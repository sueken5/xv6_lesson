# inc/env.h

```
// An environment ID 'envid_t' has three parts:
//
// +1+---------------21-----------------+--------10--------+
// |0|          Uniqueifier             |   Environment    |
// | |                                  |      Index       |
// +------------------------------------+------------------+
//                                       \--- ENVX(eid) --/
//
// The environment index ENVX(eid) equals the environment's index in the
// 'envs[]' array.  The uniqueifier distinguishes environments that were
// created at different times, but share the same environment index.
//
// All real environments are greater than 0 (so the sign bit is zero).
// envid_ts less than 0 signify errors.  The envid_t == 0 is special, and
// stands for the current environment.
```

envは32bitの中で表現。

envはほぼプロセスと同義？

# inc/trap.h

プロセッサーから出る例外や割り込み信号をここで定義してる

# inc/syscall.h

システムコールの番号をここで列挙してる

# kern/env.h

```
extern struct Env *envs;		// All environments
extern struct Env *curenv;		// Current environment
```

`*envs`はenvのリストになる。`*curenv`はその時動いてるenvのポインタとなる

```
#define ENV_PASTE3(x, y, z) x ## y ## z
```

トークン連結演算子
次はトークンを接合する演算子を紹介します
この演算子は、通常のマクロと関数マクロで有効です

トークンを接合するというのは、名前（たとえば変数名）を指定するのに
二つの文字をくっつけて置き換える作業です

トークン連結には##を使用します

変数名をくっつけてるってこと

```
abc = 10
res = ENV_PASTE3("a", "b", "c")
print(res)

=> 10
```

# kern/trap.h

```
/* The kernel's interrupt descriptor table */
extern struct Gatedesc idt[];
extern struct Pseudodesc idt_pd;
```

割り込み

# kern/trapentry.S

アセンブリレベルで割り込みはやるみたいですね。。

# lib/umain.c

ここら辺が普段やってるコマンド操作を可能にしてる

# lib/panic.c

普段見てるエラーメッセだ！

/libはプロセスむけやね

# ex1

メモリレイアウトかわっててenvが入るとこができてる。
envをmem_init()でアロケートする

mem_init()はメモリ配置をするためなんやね

突破した

[最強の参考](https://github.com/ilstam/JOS/tree/lab3/kern)

# ex2

ファイルシステムないからカーネルに直接オブジェクトファイルもたせてるからとりあえずこれでプロセスを試す

env関係が何も終わってないからやろう。

`env_init()`

envsを初期化するためにある関数。env_free_listにも初期化したEnvを入れとく

GDT周りは教科書読んで勉強してくるわ

`env_setup_vm()`

envを初期化したらそれの`env_pgdir`に仮想アドレスのポインタを詰めていく

`region_alloc()`

envに物理メモリを渡す。
page_insertしてプロセスが使えるページを増やす良い！

`load_icode()`

オブジェクトファイルをプロセスに読み込み

プログラムが動かせる状況にセッティングしててめっちゃ大事なポイント

`env_create()`

ここでenv(プロセス)を作る。バイナリファイルを入れてenvを作成するぜ！

`env_run()`

プロセス稼働へ
