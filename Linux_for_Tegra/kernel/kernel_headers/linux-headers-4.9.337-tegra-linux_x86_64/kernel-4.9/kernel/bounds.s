	.arch armv8-a
	.file	"bounds.c"
// GNU C89 (Linaro GCC 7.3-2018.05) version 7.3.1 20180425 [linaro-7.3-2018.05 revision d29120a424ecfbc167ef90065c0eeb7f91977701] (aarch64-linux-gnu)
//	compiled by GNU C version 4.8.4, GMP version 6.1.2, MPFR version 3.1.5, MPC version 1.0.3, isl version none
// GGC heuristics: --param ggc-min-expand=100 --param ggc-min-heapsize=131072
// options passed:  -nostdinc
// -I /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/arch/arm64/include
// -I ./arch/arm64/include/generated/uapi -I ./arch/arm64/include/generated
// -I /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/include
// -I ./include
// -I /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/arch/arm64/include/uapi
// -I /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/include/uapi
// -I ./include/generated/uapi
// -I /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/. -I .
// -I /dvs/git/dirty/git-master_linux/kernel/nvidia/include
// -I /dvs/git/dirty/git-master_linux/kernel/nvgpu/include
// -I /dvs/git/dirty/git-master_linux/kernel/nvgpu-next/include
// -I /dvs/git/dirty/git-master_linux/kernel/nvidia-t23x/include
// -imultiarch aarch64-linux-gnu
// -iprefix /dvs/p4/build/sw/mobile/tools/linux/linaro/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/../lib/gcc/aarch64-linux-gnu/7.3.1/
// -isysroot /dvs/p4/build/sw/mobile/tools/linux/linaro/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/../aarch64-linux-gnu/libc
// -D __KERNEL__ -D CONFIG_AS_LSE=1 -D CC_HAVE_ASM_GOTO
// -D KBUILD_BASENAME="bounds" -D KBUILD_MODNAME="bounds"
// -isystem /dvs/p4/build/sw/mobile/tools/linux/linaro/gcc-linaro-7.3.1-2018.05-x86_64_aarch64-linux-gnu/bin/../lib/gcc/aarch64-linux-gnu/7.3.1/include
// -include /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/include/linux/kconfig.h
// -MD kernel/.bounds.s.d
// /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/kernel/bounds.c
// -mlittle-endian -mgeneral-regs-only -mpc-relative-literal-loads
// -march=armv8-a -mabi=lp64 -auxbase-strip kernel/bounds.s -g -O2 -Wall
// -Wundef -Wstrict-prototypes -Wno-trigraphs
// -Werror=implicit-function-declaration -Wno-format-security
// -Wno-frame-address -Wformat-truncation=0 -Wformat-overflow=0
// -Wno-int-in-bool-context -Wframe-larger-than=2048
// -Wno-unused-but-set-variable -Wunused-const-variable=0
// -Wdeclaration-after-statement -Wno-pointer-sign -Wno-array-bounds
// -Wstringop-overflow=0 -Wno-restrict -Wno-maybe-uninitialized
// -Werror=implicit-int -Werror=strict-prototypes -Werror=date-time
// -Werror=incompatible-pointer-types -Werror=designated-init -std=gnu90 -p
// -fno-strict-aliasing -fno-common -fshort-wchar
// -fno-asynchronous-unwind-tables -fno-pic -fno-delete-null-pointer-checks
// -fno-stack-protector -fno-omit-frame-pointer -fno-optimize-sibling-calls
// -fno-var-tracking-assignments -fno-inline-functions-called-once
// -fno-strict-overflow -fno-merge-all-constants -fmerge-constants
// -fstack-check=no -fconserve-stack -fverbose-asm
// --param allow-store-data-races=0
// options enabled:  -faggressive-loop-optimizations -falign-labels
// -fauto-inc-dec -fbranch-count-reg -fcaller-saves
// -fchkp-check-incomplete-type -fchkp-check-read -fchkp-check-write
// -fchkp-instrument-calls -fchkp-narrow-bounds -fchkp-optimize
// -fchkp-store-bounds -fchkp-use-static-bounds
// -fchkp-use-static-const-bounds -fchkp-use-wrappers -fcode-hoisting
// -fcombine-stack-adjustments -fcompare-elim -fcprop-registers
// -fcrossjumping -fcse-follow-jumps -fdefer-pop -fdevirtualize
// -fdevirtualize-speculatively -fdwarf2-cfi-asm -fearly-inlining
// -feliminate-unused-debug-types -fexpensive-optimizations
// -fforward-propagate -ffp-int-builtin-inexact -ffunction-cse -fgcse
// -fgcse-lm -fgnu-runtime -fgnu-unique -fguess-branch-probability
// -fhoist-adjacent-loads -fident -fif-conversion -fif-conversion2
// -findirect-inlining -finline -finline-atomics -finline-small-functions
// -fipa-bit-cp -fipa-cp -fipa-icf -fipa-icf-functions -fipa-icf-variables
// -fipa-profile -fipa-pure-const -fipa-reference -fipa-sra -fipa-vrp
// -fira-hoist-pressure -fira-share-save-slots -fira-share-spill-slots
// -fisolate-erroneous-paths-dereference -fivopts -fkeep-static-consts
// -fleading-underscore -flifetime-dse -flra-remat -flto-odr-type-merging
// -fmath-errno -fmerge-constants -fmerge-debug-strings
// -fmove-loop-invariants -fomit-frame-pointer -foptimize-strlen
// -fpartial-inlining -fpeephole -fpeephole2 -fplt -fprefetch-loop-arrays
// -fprofile -free -freg-struct-return -freorder-blocks -freorder-functions
// -frerun-cse-after-loop -fsched-critical-path-heuristic
// -fsched-dep-count-heuristic -fsched-group-heuristic -fsched-interblock
// -fsched-last-insn-heuristic -fsched-pressure -fsched-rank-heuristic
// -fsched-spec -fsched-spec-insn-heuristic -fsched-stalled-insns-dep
// -fschedule-fusion -fschedule-insns -fschedule-insns2 -fsection-anchors
// -fsemantic-interposition -fshow-column -fshrink-wrap
// -fshrink-wrap-separate -fsigned-zeros -fsplit-ivs-in-unroller
// -fsplit-wide-types -fssa-backprop -fssa-phiopt -fstdarg-opt
// -fstore-merging -fstrict-volatile-bitfields -fsync-libcalls
// -fthread-jumps -ftoplevel-reorder -ftrapping-math -ftree-bit-ccp
// -ftree-builtin-call-dce -ftree-ccp -ftree-ch -ftree-coalesce-vars
// -ftree-copy-prop -ftree-cselim -ftree-dce -ftree-dominator-opts
// -ftree-dse -ftree-forwprop -ftree-fre -ftree-loop-if-convert
// -ftree-loop-im -ftree-loop-ivcanon -ftree-loop-optimize
// -ftree-parallelize-loops= -ftree-phiprop -ftree-pre -ftree-pta
// -ftree-reassoc -ftree-scev-cprop -ftree-sink -ftree-slsr -ftree-sra
// -ftree-switch-conversion -ftree-tail-merge -ftree-ter -ftree-vrp
// -funit-at-a-time -fvar-tracking -fverbose-asm -fzero-initialized-in-bss
// -mfix-cortex-a53-835769 -mfix-cortex-a53-843419 -mgeneral-regs-only
// -mglibc -mlittle-endian -momit-leaf-frame-pointer
// -mpc-relative-literal-loads

	.text
.Ltext0:
	.cfi_sections	.debug_frame
	.global	_mcount
	.section	.text.startup,"ax",@progbits
	.align	2
	.p2align 3,,7
	.global	main
	.type	main, %function
main:
.LFB278:
	.file 1 "/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/kernel/bounds.c"
	.loc 1 16 0
	.cfi_startproc
	stp	x29, x30, [sp, -16]!	//,,,
	.cfi_def_cfa_offset 16
	.cfi_offset 29, -16
	.cfi_offset 30, -8
	add	x29, sp, 0	//,,
	.cfi_def_cfa_register 29
// /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/kernel/bounds.c:16: {
	.loc 1 16 0
	mov	x0, x30	//,
	bl	_mcount	//
.LVL0:
// /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/kernel/bounds.c:18: 	DEFINE(NR_PAGEFLAGS, __NR_PAGEFLAGS);
	.loc 1 18 0
#APP
// 18 "/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/kernel/bounds.c" 1
	
.ascii "->NR_PAGEFLAGS 23 __NR_PAGEFLAGS"	//
// 0 "" 2
// /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/kernel/bounds.c:19: 	DEFINE(MAX_NR_ZONES, __MAX_NR_ZONES);
	.loc 1 19 0
// 19 "/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/kernel/bounds.c" 1
	
.ascii "->MAX_NR_ZONES 4 __MAX_NR_ZONES"	//
// 0 "" 2
// /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/kernel/bounds.c:21: 	DEFINE(NR_CPUS_BITS, ilog2(CONFIG_NR_CPUS));
	.loc 1 21 0
// 21 "/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/kernel/bounds.c" 1
	
.ascii "->NR_CPUS_BITS 6 ilog2(CONFIG_NR_CPUS)"	//
// 0 "" 2
// /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/kernel/bounds.c:23: 	DEFINE(SPINLOCK_SIZE, sizeof(spinlock_t));
	.loc 1 23 0
// 23 "/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/kernel/bounds.c" 1
	
.ascii "->SPINLOCK_SIZE 4 sizeof(spinlock_t)"	//
// 0 "" 2
// /dvs/git/dirty/git-master_linux/kernel/kernel-4.9/kernel/bounds.c:27: }
	.loc 1 27 0
#NO_APP
	mov	w0, 0	//,
	ldp	x29, x30, [sp], 16	//,,,
	.cfi_restore 30
	.cfi_restore 29
	.cfi_def_cfa 31, 0
	ret
	.cfi_endproc
.LFE278:
	.size	main, .-main
	.text
.Letext0:
	.file 2 "/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/include/linux/types.h"
	.file 3 "/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/include/linux/init.h"
	.file 4 "/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/arch/arm64/include/asm/cachetype.h"
	.file 5 "/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/include/linux/printk.h"
	.file 6 "/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/include/linux/jump_label.h"
	.file 7 "/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/arch/arm64/include/asm/jump_label.h"
	.file 8 "/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/arch/arm64/include/asm/insn.h"
	.file 9 "/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/include/linux/kernel.h"
	.file 10 "/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/include/linux/page-flags.h"
	.file 11 "/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/include/linux/mmzone.h"
	.file 12 "/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/include/linux/lockdep.h"
	.file 13 "/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/include/asm-generic/int-ll64.h"
	.section	.debug_info,"",@progbits
.Ldebug_info0:
	.4byte	0x4e7
	.2byte	0x4
	.4byte	.Ldebug_abbrev0
	.byte	0x8
	.uleb128 0x1
	.4byte	.LASF109
	.byte	0x1
	.4byte	.LASF110
	.4byte	.LASF111
	.4byte	.Ldebug_ranges0+0
	.8byte	0
	.4byte	.Ldebug_line0
	.uleb128 0x2
	.byte	0x1
	.byte	0x6
	.4byte	.LASF0
	.uleb128 0x2
	.byte	0x1
	.byte	0x8
	.4byte	.LASF1
	.uleb128 0x2
	.byte	0x2
	.byte	0x5
	.4byte	.LASF2
	.uleb128 0x2
	.byte	0x2
	.byte	0x7
	.4byte	.LASF3
	.uleb128 0x3
	.byte	0x4
	.byte	0x5
	.string	"int"
	.uleb128 0x2
	.byte	0x4
	.byte	0x7
	.4byte	.LASF4
	.uleb128 0x2
	.byte	0x8
	.byte	0x5
	.4byte	.LASF5
	.uleb128 0x2
	.byte	0x8
	.byte	0x7
	.4byte	.LASF6
	.uleb128 0x4
	.string	"u64"
	.byte	0xd
	.byte	0x19
	.4byte	0x5a
	.uleb128 0x2
	.byte	0x8
	.byte	0x7
	.4byte	.LASF7
	.uleb128 0x2
	.byte	0x1
	.byte	0x8
	.4byte	.LASF8
	.uleb128 0x5
	.4byte	0x73
	.uleb128 0x2
	.byte	0x8
	.byte	0x5
	.4byte	.LASF9
	.uleb128 0x6
	.byte	0x8
	.4byte	0x73
	.uleb128 0x7
	.4byte	.LASF10
	.byte	0x2
	.byte	0x1d
	.4byte	0x97
	.uleb128 0x2
	.byte	0x1
	.byte	0x2
	.4byte	.LASF11
	.uleb128 0x8
	.byte	0x4
	.byte	0x2
	.byte	0xae
	.4byte	0xb3
	.uleb128 0x9
	.4byte	.LASF33
	.byte	0x2
	.byte	0xaf
	.4byte	0x45
	.byte	0
	.byte	0
	.uleb128 0x7
	.4byte	.LASF12
	.byte	0x2
	.byte	0xb0
	.4byte	0x9e
	.uleb128 0x7
	.4byte	.LASF13
	.byte	0x3
	.byte	0x73
	.4byte	0xc9
	.uleb128 0x6
	.byte	0x8
	.4byte	0xcf
	.uleb128 0xa
	.4byte	0x45
	.uleb128 0x6
	.byte	0x8
	.4byte	0xda
	.uleb128 0xb
	.uleb128 0xc
	.4byte	0xbe
	.4byte	0xe6
	.uleb128 0xd
	.byte	0
	.uleb128 0xe
	.4byte	.LASF14
	.byte	0x3
	.byte	0x76
	.4byte	0xdb
	.uleb128 0xe
	.4byte	.LASF15
	.byte	0x3
	.byte	0x76
	.4byte	0xdb
	.uleb128 0xe
	.4byte	.LASF16
	.byte	0x3
	.byte	0x77
	.4byte	0xdb
	.uleb128 0xe
	.4byte	.LASF17
	.byte	0x3
	.byte	0x77
	.4byte	0xdb
	.uleb128 0xc
	.4byte	0x73
	.4byte	0x11d
	.uleb128 0xd
	.byte	0
	.uleb128 0xe
	.4byte	.LASF18
	.byte	0x3
	.byte	0x7e
	.4byte	0x112
	.uleb128 0xe
	.4byte	.LASF19
	.byte	0x3
	.byte	0x7f
	.4byte	0x86
	.uleb128 0xe
	.4byte	.LASF20
	.byte	0x3
	.byte	0x80
	.4byte	0x4c
	.uleb128 0xe
	.4byte	.LASF21
	.byte	0x3
	.byte	0x89
	.4byte	0x8c
	.uleb128 0xe
	.4byte	.LASF22
	.byte	0x3
	.byte	0x8f
	.4byte	0xd4
	.uleb128 0xe
	.4byte	.LASF23
	.byte	0x3
	.byte	0x91
	.4byte	0x8c
	.uleb128 0xe
	.4byte	.LASF24
	.byte	0x4
	.byte	0x2d
	.4byte	0x6c
	.uleb128 0xc
	.4byte	0x7a
	.4byte	0x175
	.uleb128 0xd
	.byte	0
	.uleb128 0x5
	.4byte	0x16a
	.uleb128 0xe
	.4byte	.LASF25
	.byte	0x5
	.byte	0xa
	.4byte	0x175
	.uleb128 0xe
	.4byte	.LASF26
	.byte	0x5
	.byte	0xb
	.4byte	0x175
	.uleb128 0xc
	.4byte	0x45
	.4byte	0x19b
	.uleb128 0xd
	.byte	0
	.uleb128 0xe
	.4byte	.LASF27
	.byte	0x5
	.byte	0x2f
	.4byte	0x190
	.uleb128 0xe
	.4byte	.LASF28
	.byte	0x5
	.byte	0x44
	.4byte	0x112
	.uleb128 0xe
	.4byte	.LASF29
	.byte	0x5
	.byte	0xaf
	.4byte	0x45
	.uleb128 0xe
	.4byte	.LASF30
	.byte	0x5
	.byte	0xb0
	.4byte	0x45
	.uleb128 0xe
	.4byte	.LASF31
	.byte	0x5
	.byte	0xb1
	.4byte	0x45
	.uleb128 0xe
	.4byte	.LASF32
	.byte	0x6
	.byte	0x52
	.4byte	0x8c
	.uleb128 0xf
	.4byte	.LASF112
	.byte	0x18
	.byte	0x7
	.byte	0x3b
	.4byte	0x20e
	.uleb128 0x9
	.4byte	.LASF34
	.byte	0x7
	.byte	0x3c
	.4byte	0x255
	.byte	0
	.uleb128 0x9
	.4byte	.LASF35
	.byte	0x7
	.byte	0x3d
	.4byte	0x255
	.byte	0x8
	.uleb128 0x10
	.string	"key"
	.byte	0x7
	.byte	0x3e
	.4byte	0x255
	.byte	0x10
	.byte	0
	.uleb128 0x11
	.4byte	.LASF36
	.byte	0x8
	.2byte	0x1a7
	.4byte	0x21a
	.uleb128 0x12
	.4byte	0x8c
	.4byte	0x229
	.uleb128 0x13
	.4byte	0x6c
	.byte	0
	.uleb128 0xc
	.4byte	0x244
	.4byte	0x239
	.uleb128 0x14
	.4byte	0x6c
	.byte	0xf
	.byte	0
	.uleb128 0x5
	.4byte	0x229
	.uleb128 0x6
	.byte	0x8
	.4byte	0x20e
	.uleb128 0x5
	.4byte	0x23e
	.uleb128 0x15
	.4byte	.LASF37
	.byte	0x8
	.2byte	0x1a8
	.4byte	0x239
	.uleb128 0x7
	.4byte	.LASF38
	.byte	0x7
	.byte	0x39
	.4byte	0x61
	.uleb128 0xc
	.4byte	0x1dd
	.4byte	0x26b
	.uleb128 0xd
	.byte	0
	.uleb128 0xe
	.4byte	.LASF39
	.byte	0x6
	.byte	0x87
	.4byte	0x260
	.uleb128 0xe
	.4byte	.LASF40
	.byte	0x6
	.byte	0x88
	.4byte	0x260
	.uleb128 0x16
	.4byte	.LASF42
	.uleb128 0x5
	.4byte	0x281
	.uleb128 0x15
	.4byte	.LASF41
	.byte	0x5
	.2byte	0x1cc
	.4byte	0x286
	.uleb128 0x16
	.4byte	.LASF43
	.uleb128 0x15
	.4byte	.LASF44
	.byte	0x9
	.2byte	0x104
	.4byte	0x297
	.uleb128 0x12
	.4byte	0x7f
	.4byte	0x2b7
	.uleb128 0x13
	.4byte	0x45
	.byte	0
	.uleb128 0x15
	.4byte	.LASF45
	.byte	0x9
	.2byte	0x105
	.4byte	0x2c3
	.uleb128 0x6
	.byte	0x8
	.4byte	0x2a8
	.uleb128 0x15
	.4byte	.LASF46
	.byte	0x9
	.2byte	0x1bd
	.4byte	0x45
	.uleb128 0x15
	.4byte	.LASF47
	.byte	0x9
	.2byte	0x1be
	.4byte	0x45
	.uleb128 0x15
	.4byte	.LASF48
	.byte	0x9
	.2byte	0x1bf
	.4byte	0x45
	.uleb128 0x15
	.4byte	.LASF49
	.byte	0x9
	.2byte	0x1c0
	.4byte	0x45
	.uleb128 0x15
	.4byte	.LASF50
	.byte	0x9
	.2byte	0x1c1
	.4byte	0x45
	.uleb128 0x15
	.4byte	.LASF51
	.byte	0x9
	.2byte	0x1c2
	.4byte	0x45
	.uleb128 0x15
	.4byte	.LASF52
	.byte	0x9
	.2byte	0x1c3
	.4byte	0x45
	.uleb128 0x15
	.4byte	.LASF53
	.byte	0x9
	.2byte	0x1c4
	.4byte	0x45
	.uleb128 0x15
	.4byte	.LASF54
	.byte	0x9
	.2byte	0x1c6
	.4byte	0x8c
	.uleb128 0x15
	.4byte	.LASF55
	.byte	0x9
	.2byte	0x1cd
	.4byte	0xb3
	.uleb128 0x15
	.4byte	.LASF56
	.byte	0x9
	.2byte	0x1e1
	.4byte	0x45
	.uleb128 0x15
	.4byte	.LASF57
	.byte	0x9
	.2byte	0x1e3
	.4byte	0x8c
	.uleb128 0x17
	.4byte	.LASF67
	.byte	0x7
	.byte	0x4
	.4byte	0x4c
	.byte	0x9
	.2byte	0x1e6
	.4byte	0x390
	.uleb128 0x18
	.4byte	.LASF58
	.byte	0
	.uleb128 0x18
	.4byte	.LASF59
	.byte	0x1
	.uleb128 0x18
	.4byte	.LASF60
	.byte	0x2
	.uleb128 0x18
	.4byte	.LASF61
	.byte	0x3
	.uleb128 0x18
	.4byte	.LASF62
	.byte	0x4
	.uleb128 0x18
	.4byte	.LASF63
	.byte	0x5
	.byte	0
	.uleb128 0x15
	.4byte	.LASF64
	.byte	0x9
	.2byte	0x1ed
	.4byte	0x359
	.uleb128 0x15
	.4byte	.LASF65
	.byte	0x9
	.2byte	0x200
	.4byte	0x175
	.uleb128 0x15
	.4byte	.LASF66
	.byte	0x9
	.2byte	0x20b
	.4byte	0x175
	.uleb128 0x19
	.4byte	.LASF68
	.byte	0x7
	.byte	0x4
	.4byte	0x4c
	.byte	0xa
	.byte	0x4a
	.4byte	0x486
	.uleb128 0x18
	.4byte	.LASF69
	.byte	0
	.uleb128 0x18
	.4byte	.LASF70
	.byte	0x1
	.uleb128 0x18
	.4byte	.LASF71
	.byte	0x2
	.uleb128 0x18
	.4byte	.LASF72
	.byte	0x3
	.uleb128 0x18
	.4byte	.LASF73
	.byte	0x4
	.uleb128 0x18
	.4byte	.LASF74
	.byte	0x5
	.uleb128 0x18
	.4byte	.LASF75
	.byte	0x6
	.uleb128 0x18
	.4byte	.LASF76
	.byte	0x7
	.uleb128 0x18
	.4byte	.LASF77
	.byte	0x8
	.uleb128 0x18
	.4byte	.LASF78
	.byte	0x9
	.uleb128 0x18
	.4byte	.LASF79
	.byte	0xa
	.uleb128 0x18
	.4byte	.LASF80
	.byte	0xb
	.uleb128 0x18
	.4byte	.LASF81
	.byte	0xc
	.uleb128 0x18
	.4byte	.LASF82
	.byte	0xd
	.uleb128 0x18
	.4byte	.LASF83
	.byte	0xe
	.uleb128 0x18
	.4byte	.LASF84
	.byte	0xf
	.uleb128 0x18
	.4byte	.LASF85
	.byte	0x10
	.uleb128 0x18
	.4byte	.LASF86
	.byte	0x11
	.uleb128 0x18
	.4byte	.LASF87
	.byte	0x12
	.uleb128 0x18
	.4byte	.LASF88
	.byte	0x13
	.uleb128 0x18
	.4byte	.LASF89
	.byte	0x14
	.uleb128 0x18
	.4byte	.LASF90
	.byte	0x15
	.uleb128 0x18
	.4byte	.LASF91
	.byte	0x16
	.uleb128 0x18
	.4byte	.LASF92
	.byte	0x17
	.uleb128 0x18
	.4byte	.LASF93
	.byte	0xa
	.uleb128 0x18
	.4byte	.LASF94
	.byte	0xe
	.uleb128 0x18
	.4byte	.LASF95
	.byte	0xa
	.uleb128 0x18
	.4byte	.LASF96
	.byte	0x4
	.uleb128 0x18
	.4byte	.LASF97
	.byte	0xa
	.uleb128 0x18
	.4byte	.LASF98
	.byte	0xd
	.uleb128 0x18
	.4byte	.LASF99
	.byte	0xe
	.uleb128 0x18
	.4byte	.LASF100
	.byte	0x13
	.byte	0
	.uleb128 0x17
	.4byte	.LASF101
	.byte	0x7
	.byte	0x4
	.4byte	0x4c
	.byte	0xb
	.2byte	0x123
	.4byte	0x4b7
	.uleb128 0x18
	.4byte	.LASF102
	.byte	0
	.uleb128 0x18
	.4byte	.LASF103
	.byte	0x1
	.uleb128 0x18
	.4byte	.LASF104
	.byte	0x2
	.uleb128 0x18
	.4byte	.LASF105
	.byte	0x3
	.uleb128 0x18
	.4byte	.LASF106
	.byte	0x4
	.byte	0
	.uleb128 0xe
	.4byte	.LASF107
	.byte	0xc
	.byte	0x10
	.4byte	0x45
	.uleb128 0xe
	.4byte	.LASF108
	.byte	0xc
	.byte	0x11
	.4byte	0x45
	.uleb128 0x1a
	.4byte	.LASF113
	.byte	0x1
	.byte	0xf
	.4byte	0x45
	.8byte	.LFB278
	.8byte	.LFE278-.LFB278
	.uleb128 0x1
	.byte	0x9c
	.byte	0
	.section	.debug_abbrev,"",@progbits
.Ldebug_abbrev0:
	.uleb128 0x1
	.uleb128 0x11
	.byte	0x1
	.uleb128 0x25
	.uleb128 0xe
	.uleb128 0x13
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x1b
	.uleb128 0xe
	.uleb128 0x55
	.uleb128 0x17
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x10
	.uleb128 0x17
	.byte	0
	.byte	0
	.uleb128 0x2
	.uleb128 0x24
	.byte	0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3e
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0xe
	.byte	0
	.byte	0
	.uleb128 0x3
	.uleb128 0x24
	.byte	0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3e
	.uleb128 0xb
	.uleb128 0x3
	.uleb128 0x8
	.byte	0
	.byte	0
	.uleb128 0x4
	.uleb128 0x16
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x5
	.uleb128 0x26
	.byte	0
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x6
	.uleb128 0xf
	.byte	0
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x7
	.uleb128 0x16
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x8
	.uleb128 0x13
	.byte	0x1
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x9
	.uleb128 0xd
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x38
	.uleb128 0xb
	.byte	0
	.byte	0
	.uleb128 0xa
	.uleb128 0x15
	.byte	0
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0xb
	.uleb128 0x15
	.byte	0
	.uleb128 0x27
	.uleb128 0x19
	.byte	0
	.byte	0
	.uleb128 0xc
	.uleb128 0x1
	.byte	0x1
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0xd
	.uleb128 0x21
	.byte	0
	.byte	0
	.byte	0
	.uleb128 0xe
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3c
	.uleb128 0x19
	.byte	0
	.byte	0
	.uleb128 0xf
	.uleb128 0x13
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x10
	.uleb128 0xd
	.byte	0
	.uleb128 0x3
	.uleb128 0x8
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x38
	.uleb128 0xb
	.byte	0
	.byte	0
	.uleb128 0x11
	.uleb128 0x16
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x12
	.uleb128 0x15
	.byte	0x1
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x13
	.uleb128 0x5
	.byte	0
	.uleb128 0x49
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x14
	.uleb128 0x21
	.byte	0
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x2f
	.uleb128 0xb
	.byte	0
	.byte	0
	.uleb128 0x15
	.uleb128 0x34
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3c
	.uleb128 0x19
	.byte	0
	.byte	0
	.uleb128 0x16
	.uleb128 0x13
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3c
	.uleb128 0x19
	.byte	0
	.byte	0
	.uleb128 0x17
	.uleb128 0x4
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3e
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0x5
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x18
	.uleb128 0x28
	.byte	0
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x1c
	.uleb128 0xb
	.byte	0
	.byte	0
	.uleb128 0x19
	.uleb128 0x4
	.byte	0x1
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3e
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0xb
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x1
	.uleb128 0x13
	.byte	0
	.byte	0
	.uleb128 0x1a
	.uleb128 0x2e
	.byte	0
	.uleb128 0x3f
	.uleb128 0x19
	.uleb128 0x3
	.uleb128 0xe
	.uleb128 0x3a
	.uleb128 0xb
	.uleb128 0x3b
	.uleb128 0xb
	.uleb128 0x27
	.uleb128 0x19
	.uleb128 0x49
	.uleb128 0x13
	.uleb128 0x11
	.uleb128 0x1
	.uleb128 0x12
	.uleb128 0x7
	.uleb128 0x40
	.uleb128 0x18
	.uleb128 0x2116
	.uleb128 0x19
	.byte	0
	.byte	0
	.byte	0
	.section	.debug_aranges,"",@progbits
	.4byte	0x2c
	.2byte	0x2
	.4byte	.Ldebug_info0
	.byte	0x8
	.byte	0
	.2byte	0
	.2byte	0
	.8byte	.LFB278
	.8byte	.LFE278-.LFB278
	.8byte	0
	.8byte	0
	.section	.debug_ranges,"",@progbits
.Ldebug_ranges0:
	.8byte	.LFB278
	.8byte	.LFE278
	.8byte	0
	.8byte	0
	.section	.debug_line,"",@progbits
.Ldebug_line0:
	.section	.debug_str,"MS",@progbits,1
.LASF42:
	.string	"file_operations"
.LASF59:
	.string	"SYSTEM_BOOTING"
.LASF14:
	.string	"__con_initcall_start"
.LASF13:
	.string	"initcall_t"
.LASF87:
	.string	"PG_mappedtodisk"
.LASF25:
	.string	"linux_banner"
.LASF70:
	.string	"PG_waiters"
.LASF47:
	.string	"panic_timeout"
.LASF96:
	.string	"PG_savepinned"
.LASF97:
	.string	"PG_foreign"
.LASF82:
	.string	"PG_private"
.LASF12:
	.string	"atomic_t"
.LASF2:
	.string	"short int"
.LASF55:
	.string	"panic_cpu"
.LASF26:
	.string	"linux_proc_banner"
.LASF64:
	.string	"system_state"
.LASF95:
	.string	"PG_pinned"
.LASF62:
	.string	"SYSTEM_POWER_OFF"
.LASF113:
	.string	"main"
.LASF31:
	.string	"kptr_restrict"
.LASF88:
	.string	"PG_reclaim"
.LASF108:
	.string	"lock_stat"
.LASF43:
	.string	"atomic_notifier_head"
.LASF94:
	.string	"PG_fscache"
.LASF102:
	.string	"ZONE_DMA"
.LASF50:
	.string	"panic_on_io_nmi"
.LASF110:
	.string	"/dvs/git/dirty/git-master_linux/kernel/kernel-4.9/kernel/bounds.c"
.LASF39:
	.string	"__start___jump_table"
.LASF81:
	.string	"PG_reserved"
.LASF44:
	.string	"panic_notifier_list"
.LASF27:
	.string	"console_printk"
.LASF60:
	.string	"SYSTEM_RUNNING"
.LASF69:
	.string	"PG_locked"
.LASF54:
	.string	"crash_kexec_post_notifiers"
.LASF92:
	.string	"__NR_PAGEFLAGS"
.LASF10:
	.string	"bool"
.LASF0:
	.string	"signed char"
.LASF89:
	.string	"PG_swapbacked"
.LASF63:
	.string	"SYSTEM_RESTART"
.LASF99:
	.string	"PG_double_map"
.LASF29:
	.string	"printk_delay_msec"
.LASF5:
	.string	"long long int"
.LASF58:
	.string	"SYSTEM_BOOTING_SINGLECORE"
.LASF104:
	.string	"ZONE_MOVABLE"
.LASF65:
	.string	"hex_asc"
.LASF83:
	.string	"PG_private_2"
.LASF41:
	.string	"kmsg_fops"
.LASF45:
	.string	"panic_blink"
.LASF20:
	.string	"reset_devices"
.LASF28:
	.string	"devkmsg_log_str"
.LASF103:
	.string	"ZONE_NORMAL"
.LASF80:
	.string	"PG_arch_1"
.LASF76:
	.string	"PG_workingset"
.LASF36:
	.string	"pstate_check_t"
.LASF16:
	.string	"__security_initcall_start"
.LASF106:
	.string	"__MAX_NR_ZONES"
.LASF105:
	.string	"ZONE_DEVICE"
.LASF1:
	.string	"unsigned char"
.LASF111:
	.string	"/dvs/git/dirty/git-master_linux/out/nvidia/kernel-extmod-linux_x86_64-build"
.LASF33:
	.string	"counter"
.LASF112:
	.string	"jump_entry"
.LASF109:
	.ascii	"GNU C89 7.3.1 20180425 [linaro-7.3-2018.05 revision d29120a4"
	.ascii	"24ecfbc167ef90065c0eeb7f91977701] -mlittle-endian -mgeneral-"
	.ascii	"regs-only -mpc-relative-literal-loads -march=armv8-a -mabi=l"
	.ascii	"p64 -g -O2 -std=gnu90 -p -fno-strict-aliasing -fno-common -f"
	.ascii	"short-wchar -fno-asynchronous-unwind-tables -fno-pic -fno-de"
	.ascii	"lete-null-pointer-checks -fno-stack-"
	.string	"protector -fno-omit-frame-pointer -fno-optimize-sibling-calls -fno-var-tracking-assignments -fno-inline-functions-called-once -fno-strict-overflow -fno-merge-all-constants -fmerge-constants -fstack-check=no -fconserve-stack --param allow-store-data-races=0"
.LASF72:
	.string	"PG_uptodate"
.LASF19:
	.string	"saved_command_line"
.LASF91:
	.string	"PG_mlocked"
.LASF24:
	.string	"__icache_flags"
.LASF6:
	.string	"long long unsigned int"
.LASF40:
	.string	"__stop___jump_table"
.LASF4:
	.string	"unsigned int"
.LASF15:
	.string	"__con_initcall_end"
.LASF98:
	.string	"PG_slob_free"
.LASF71:
	.string	"PG_referenced"
.LASF73:
	.string	"PG_dirty"
.LASF34:
	.string	"code"
.LASF67:
	.string	"system_states"
.LASF3:
	.string	"short unsigned int"
.LASF93:
	.string	"PG_checked"
.LASF8:
	.string	"char"
.LASF9:
	.string	"long int"
.LASF68:
	.string	"pageflags"
.LASF48:
	.string	"panic_on_oops"
.LASF37:
	.string	"aarch32_opcode_cond_checks"
.LASF57:
	.string	"early_boot_irqs_disabled"
.LASF11:
	.string	"_Bool"
.LASF74:
	.string	"PG_lru"
.LASF21:
	.string	"rodata_enabled"
.LASF90:
	.string	"PG_unevictable"
.LASF61:
	.string	"SYSTEM_HALT"
.LASF7:
	.string	"long unsigned int"
.LASF107:
	.string	"prove_locking"
.LASF86:
	.string	"PG_swapcache"
.LASF38:
	.string	"jump_label_t"
.LASF75:
	.string	"PG_active"
.LASF85:
	.string	"PG_head"
.LASF101:
	.string	"zone_type"
.LASF18:
	.string	"boot_command_line"
.LASF22:
	.string	"late_time_init"
.LASF79:
	.string	"PG_owner_priv_1"
.LASF51:
	.string	"panic_on_warn"
.LASF35:
	.string	"target"
.LASF49:
	.string	"panic_on_unrecovered_nmi"
.LASF23:
	.string	"initcall_debug"
.LASF77:
	.string	"PG_error"
.LASF84:
	.string	"PG_writeback"
.LASF52:
	.string	"sysctl_panic_on_rcu_stall"
.LASF17:
	.string	"__security_initcall_end"
.LASF78:
	.string	"PG_slab"
.LASF30:
	.string	"dmesg_restrict"
.LASF56:
	.string	"root_mountflags"
.LASF46:
	.string	"oops_in_progress"
.LASF53:
	.string	"sysctl_panic_on_stackoverflow"
.LASF32:
	.string	"static_key_initialized"
.LASF100:
	.string	"PG_isolated"
.LASF66:
	.string	"hex_asc_upper"
	.ident	"GCC: (Linaro GCC 7.3-2018.05) 7.3.1 20180425 [linaro-7.3-2018.05 revision d29120a424ecfbc167ef90065c0eeb7f91977701]"
	.section	.note.GNU-stack,"",@progbits
