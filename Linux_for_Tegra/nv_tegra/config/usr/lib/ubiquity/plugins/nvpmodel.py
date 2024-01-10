#!/usr/bin/env python
#
# Copyright (c) 2020, NVIDIA CORPORATION. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
# DEALINGS IN THE SOFTWARE.

import os
import gi
import re
import sys
import subprocess
import fileinput

from ubiquity import plugin
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk

# Plugin settings
NAME = 'nvpmodel'
AFTER = 'usersetup'
WEIGHT = 10

conf_paths = [
    "/odm/etc/nvpmodel.conf",
    "/vendor/etc/nvpmodel.conf",
    "/etc/nvpmodel.conf",
]

def get_max_freq(freq_path, strip=False):
    fd = open(freq_path, 'r')
    max_freq = str(fd.read())
    if strip:
        max_freq = max_freq.rstrip()
    return max_freq

def get_min_available_freq(freq_path, strip=False):
    fd = open(freq_path, 'r')
    freq_str = str(fd.read())
    if strip:
        freq_str = freq_str.rstrip()
    freqs = freq_str.split(' ')
    min_freq = freqs[0]
    return min_freq

def get_max_available_freq(freq_path, strip=False):
    fd = open(freq_path, 'r')
    freq_str = str(fd.read())
    if strip:
        freq_str = freq_str.rstrip()
    freqs = freq_str.split(' ')
    max_freq = freqs[len(freqs)-2]
    return max_freq

def parse_preset(conf):
    regex = re.compile("<\s+PM_CONFIG\s+DEFAULT=(\d)\s+>")
    for line in conf:
        m = regex.match(line)
        if m != None:
            return m.group(1)

class nvpmodel_setting(object):
    def __init__(self, name, attr, val):
        self.name = name
        self.attr = attr
        self.value = val

    def __repr__(self):
        return str([self.name, self.attr, self.value])

def parse_settings(vals):
    settings = []
    for v in vals:
        name, attr, val = v
        settings.append(nvpmodel_setting(name, attr, val))
    return settings

class power_mode(object):
    def __init__(self, mode_id, name, vals):
        self.id = mode_id
        self.name = name
        self.settings = parse_settings(vals)

    def __repr__(self):
        return str([self.id, self.name, self.vals])

def parse_power_mode(conf):
    modes = []
    regex = re.compile("<\s+POWER_MODEL\s+ID=(\d+)\s+NAME=(\w+)\s+>")
    for line in conf:
        m = regex.match(line)
        if m != None:
            vals = []
            for arg in conf[conf.index(line)+1:]:
                if arg[0] != '<':
                    vals.append(arg.split())
                else:
                    break
            modes.append(power_mode(m.group(1), m.group(2), vals))
    return modes

class param_arg(object):
    def __init__(self, arg):
        self.name, self.path = arg.split()

    def __repr__(self):
        return str([self.name, self.path])

def parse_args(args):
    param_args = []
    for a in args:
        param_args.append(param_arg(a))
    return param_args

class nvpmodel_param(object):
    def __init__(self, p_type, name, args):
        self.name = name
        self.type = p_type
        self.args = parse_args(args)

    def __repr__(self):
        return str([self.name, self.type, self.args])

def parse_params(conf):
    params = []
    regex = re.compile("<\s+PARAM\s+TYPE=(\w+)\s+NAME=(\w+)\s+>")
    for line in conf:
        m = regex.match(line)
        if m != None:
            args = []
            for arg in conf[conf.index(line)+1:]:
                if arg[0] != '<':
                    args.append(arg)
                else:
                    break
            params.append(nvpmodel_param(m.group(1), m.group(2), args))
    return params

class nvpmodel_conf(object):
    def __init__(self, conf):
        self.preset = parse_preset(conf)
        self.power_modes = parse_power_mode(conf)
        self.params = parse_params(conf)

def import_conf(paths):
    conf = []
    conf_file = None

    for p in paths:
        if os.path.isfile(p):
            f = open(p)
            conf_file = p
            for line in f:
                line = line.strip()
                if line == '' or line[0] == '#':
                    continue
                conf.append(line)
            f.close()
            break

    return conf_file, conf

class nvpmodel(object):
    def __init__(self):
        self.conf_path, self.raw_conf = import_conf(conf_paths)
        if not self.conf_path:
            return None

        self.conf = nvpmodel_conf(self.raw_conf)
        if os.path.islink(self.conf_path):
            self.conf_path = os.readlink(self.conf_path)

    def preset_mode(self):
        return self.conf.preset

    def power_modes(self):
        return self.conf.power_modes

    def get_name_by_id(self, mode_id):
        for m in self.conf.power_modes:
            if mode_id == m.id:
                return m.name
        return ""

    def cpu_count(self):
        try:
            with open("/sys/devices/system/cpu/present") as f:
                for line in f:
                    return int(line.split('-')[1]) + 1
        except IOError:
                return 1

class ListBoxRowWithData(Gtk.ListBoxRow):
    def __init__(self, data):
        super(Gtk.ListBoxRow, self).__init__()
        self.data = data
        self.add(Gtk.Label(label=data, xalign=0))



class PageGtk(plugin.PluginUI):
    plugin_title = 'ubiquity/text/nvpmodel_label'

    def __init__(self, controller, *args, **kwargs):
        super(PageGtk, self).__init__(self, *args, **kwargs)
        self.script = '/usr/lib/nvidia/nvpmodel/nvpmodel.sh'
        self.mode_id = 0
        self.online_cpu_cores = 0
        self.cpu_freqs = ""
        self.gpu_freqs = ""
        self.emc_freqs = "/sys/kernel/debug/tegra_bwmgr/emc_max_rate"
        self.cpu_max_freq = 0
        self.gpu_max_freq = 0
        self.emc_max_freq = 0
        self.dla_max_freq = 0
        self.cpu_min_freq = 0
        self.gpu_min_freq = 0

        container = Gtk.VBox(spacing=20)
        container.set_border_width(20)
        container.set_homogeneous(False)

        label_description = Gtk.Label('Set Nvpmodel Mode:', xalign=0)
        label_description.set_justify(Gtk.Justification.LEFT)
        label_description.show()
        container.pack_start(label_description, False, False, 0)

        self.nvpm = nvpmodel()
        if not self.nvpm.conf_path:
            return
        if not self.nvpm.conf.preset:
            return
        self.default_mode_id = self.nvpm.conf.preset
        self.default_mode_name = self.nvpm.get_name_by_id(self.default_mode_id)
        self.mname_list = []
        for m in self.nvpm.power_modes():
            self.mname_list.append(m.name)
 
        self.box_outer = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)

        self.listbox = Gtk.ListBox()

        for mtxt in self.mname_list:
            if mtxt == self.default_mode_name:
                mtxt = mtxt + " - (Default)"
            self.listbox.add(ListBoxRowWithData(mtxt))

        def get_row_with_default_mode(mode_name, row_count):
            for i in range(row_count):
                row = self.listbox.get_row_at_index(i)
                if row.data.split(" ")[0] == mode_name:
                    return row
            return 0

        def update_mode_values(req_mode):
            self.online_cpu_cores = 0
            self.cpu_max_freq = 0
            self.gpu_max_freq = 0
            self.emc_max_freq = 0
            self.dla_max_freq = 0
            self.cpu_min_freq = 0
            self.gpu_min_freq = 0

            if req_mode.name == "MAXN":
                for setting in req_mode.settings:
                    if setting.name == "CPU_DENVER_0":
                        if setting.attr == "MIN_FREQ":
                            self.cpu_min_freq = int(int(setting.value) * 1000)

                    if setting.name == "GPU":
                        if setting.attr == "MIN_FREQ":
                            self.gpu_min_freq = setting.value

                if os.path.exists(self.cpu_freqs):
                    self.cpu_max_freq = get_max_available_freq(self.cpu_freqs)
                    self.cpu_max_freq = int(int(self.cpu_max_freq) * 1000)
                if os.path.exists(self.gpu_freqs):
                    self.gpu_max_freq = get_max_available_freq(self.gpu_freqs, True)
                if os.path.exists(self.emc_freqs):
                    self.emc_max_freq = get_max_freq(self.emc_freqs, True)
                self.online_cpu_cores = self.nvpm.cpu_count()
            else:
                for setting in req_mode.settings:

                    if setting.name == "CPU_ONLINE":
                        self.online_cpu_cores = self.online_cpu_cores + int(setting.value)

                    if setting.name == "CPU_DENVER_0":
                        if setting.attr == "MIN_FREQ":
                            self.cpu_min_freq = int(int(setting.value) * 1000)
                        if setting.attr == "MAX_FREQ":
                            self.cpu_max_freq = int(int(setting.value) * 1000)

                    if setting.name == "CPU_A57":
                        if setting.attr == "MIN_FREQ":
                            self.cpu_min_freq = int(int(setting.value) * 1000)
                        if setting.attr == "MAX_FREQ":
                            self.cpu_max_freq = int(int(setting.value) * 1000)

                    if setting.name == "GPU":
                        if setting.attr == "MIN_FREQ":
                            self.gpu_min_freq = setting.value
                        if setting.attr == "MAX_FREQ":
                            self.gpu_max_freq = setting.value

                    if setting.name == "EMC":
                        if setting.attr == "MAX_FREQ":
                            self.emc_max_freq = setting.value
                            self.emc_max_freq = self.emc_max_freq

                    if setting.name == "DLA_CORE":
                        if setting.attr == "MAX_FREQ":
                            self.dla_max_freq = setting.value

            if int(self.cpu_min_freq) <= 0:
                if os.path.exists(self.cpu_freqs):
                    self.cpu_min_freq = get_min_available_freq(self.cpu_freqs)
                    self.cpu_min_freq = int(int(self.cpu_min_freq) * 1000)
            if int(self.gpu_min_freq) <= 0:
                if os.path.exists(self.gpu_freqs):
                    self.gpu_min_freq = get_min_available_freq(self.gpu_freqs, True)
            if int(self.cpu_max_freq) <= 0:
                if os.path.exists(self.cpu_freqs):
                    self.cpu_max_freq = get_max_available_freq(self.cpu_freqs)
                    self.cpu_max_freq = int(int(self.cpu_max_freq) * 1000)
            if int(self.gpu_max_freq) <= 0:
                if os.path.exists(self.gpu_freqs):
                    self.gpu_max_freq = get_max_available_freq(self.gpu_freqs, True)
            if int(self.emc_max_freq) <= 0:
                 if os.path.exists(self.emc_freqs):
                    self.emc_max_freq = get_max_freq(self.emc_freqs, True)

        def get_selected_mode(label):
            for md in self.nvpm.power_modes():
                if md.name == label:
                    break
            return md

        def get_param_paths():
            for p in self.nvpm.conf.params:
                for a in p.args:
                    if p.name == "CPU_A57":
                        if a.name == "FREQ_TABLE":
                            self.cpu_freqs = a.path
                    if p.name == "CPU_DENVER_0":
                        if a.name == "FREQ_TABLE":
                            self.cpu_freqs = a.path
                    if p.name == "GPU":
                        if a.name == "FREQ_TABLE":
                            self.gpu_freqs = a.path

        def on_row_selected(listbox_widget, row):
            get_param_paths()
            md = get_selected_mode(row.data.split(" ")[0])
            update_mode_values(md)
            self.mode_id = md.id

            mode_info_data = [
                self.online_cpu_cores,
                self.cpu_min_freq,
                self.cpu_max_freq,
                self.gpu_min_freq,
                self.gpu_max_freq,
                self.emc_max_freq
            ]

            children = self.vbox1.get_children();
            for element in children:
                self.vbox1.remove(element)

            for item in mode_info_data:
                label = Gtk.Label(label=item, xalign=0)
                self.vbox1.pack_start(label, True, True, 0)
            self.listbox2.show_all()


        self.box_outer.pack_start(self.listbox, True, True, 0)

        self.srow = get_row_with_default_mode(self.default_mode_name, len(self.listbox))
        if self.srow:
            self.listbox.select_row(self.srow)

        self.listbox2 = Gtk.ListBox()
        self.listbox2.set_selection_mode(Gtk.SelectionMode.NONE)
        self.box_outer.pack_start(self.listbox2, True, True, 0)

        self.lrow = Gtk.ListBoxRow()
        self.hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=50)
        self.lrow.add(self.hbox)
        self.vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.vbox1 = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        self.hbox.pack_start(self.vbox, True, True, 0)
        self.hbox.pack_start(self.vbox1, True, True, 0)

        mode_info_labels = [
            "CPU Online Cores:",
            "CPU Min Freq:",
            "CPU Max Freq:",
            "GPU Min Freq:",
            "GPU Max Freq:",
            "EMC Max Freq:"
        ]

        for item in mode_info_labels:
            label = Gtk.Label(label=item, xalign=0)
            self.vbox.pack_start(label, True, True, 0)


        self.listbox.connect("row-selected", on_row_selected)
        self.listbox2.add(self.lrow)


        self.listbox.show_all()
        self.listbox2.show_all()
        self.box_outer.show()
        container.pack_start(self.box_outer, True, True, 0)

        label2 = Gtk.Label(
                'If you are unsure which mode to select, keep the default setting.\n' +
                'This setting can be changed at runtime using the nvpmodel GUI or nvpmodel command line utility.\n' +
                'Refer to NVIDIA Jetson Linux Developer Guide for further information.', xalign=0)
        label2.set_justify(Gtk.Justification.LEFT)
        label2.show()
        container.pack_start(label2, False, False, 0)


        self.page = container
        self.controller = controller
        self.plugin_widgets = self.page

    def plugin_on_next_clicked(self):
        subprocess.check_output([self.script, self.default_mode_id, self.mode_id], universal_newlines=True).strip()

class PageDebconf(plugin.Plugin):
    plugin_title = 'ubiquity/text/nvpmodel_label'

    def __init__(self, controller, *args, **kwargs):
        super(PageDebconf, self).__init__(self, *args, **kwargs)
        self.controller = controller

class Page(plugin.Plugin):
    def prepare(self, unfiltered=False):
        if os.environ.get('UBIQUITY_FRONTEND', None) == 'debconf_ui':
            nvpmodel_script = '/usr/lib/nvidia/nvpmodel/nvpmodel-query'
            return [nvpmodel_script]
        return
