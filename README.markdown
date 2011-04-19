<h1>tDiary からMovable Typeへの移行</h1>
( 変換実績 tDiary(1.5.x) → Movable Type (2.661) )
<HR>
<P>まずは、とくにtDiaryに不満があるわけでもなく、またMovable Typeへの移行を考えているわけでもないのです。</P>
<P>ただ、探してみたところぜんぜん変換ツールがない、またいつでも移行できるように自分用のツールを作ってみました。ツールがないのは、pluginのサポートができなかったり、十人十色のtDiaryのつかい方に対して、適切な変換方法が見つけられないからだと思います。</P>
<P>それでも、とりあえずの参考程度にはなるのではないかと、ここに公開してみます。一応、ツッコミ→コメントの変換、TrackBackの移行には対応してます。<BR>
日記の書式を選んでしまうのは、私用ということで、御免なさいゆるしてください。TITLEがちゃんと取れているかくらいを確認してもらえると良いとおもいます。
<small>(ただし、同じ日に複数の日記をつけている場合、コメントについては、一番最初に書いた日記に対してのコメントとして処理しちゃいます。)</small></P>
<P>なお、変換前のtDiaryは→<A href="http://kenstar.org/~kenstar/tdiary/200402.html">こちら</A>、<BR>
変換後のMovable Typeは→<A href="http://kenstar.org/~kenstar/ks/archives/2004/02.html">こちら</A></P>
<h2>予備知識</h2>
<P>tDiaryのキャッシュは、tdiary.confの中に記述されている、@data_pathにある。
このディレクトリの下に、2004/200404.td2というように、「年/年月.td2」として保存されています。元データは、
*.td2, *tdcです。</p>
<small>*.td2‥日記データ、*.tdc‥ツッコミ・TrackBackデータ</small></P>
<h2>使用方法</h2>
<P>「t2m.pl -d 200405.td」というように指定してください。これで、200405.td2, 200405.tdcの２ファイルを読んで変換し、標準出力に出力ます。</P>
<h2>注意</h2>
<P>やってないことがいくつもあります。<s>カテゴリー対応とか、非表示設定日記対応、</s>画像移行、リンク元データ移行など。その他機能についても当然無保証ですよ。</P>
<p>(追記2004/5/8)とりあえず、カテゴリー対応と、非表示設定日記コメント対応をしてみました。でも、無保障です。</P>

<hr>
<P><b>蛇足(importの仕方)</b></P>
<OL>
  <LI>作成したファイルを、Movable Typeをインストールしたディレクトリの下にimportディレクトリを作成
  <LI>importディレクトリにlog2mt.logとして保存
  <LI>MTの管理画面の「import」からimportを実行。「エントリーの投稿者を自分にする」のチェックをつける
  <LI>「エントリーの読み込み」ボタンを押す
  <LI>importディレクトリにあるlog2mt.logを削除。そのままにしておくと、重複して登録されてしまう。
</OL>
<P><b>蛇足(変換の際のコツ)</b></P>
年、月をまたがって変換したい場合、for文とかをつかうと楽。たとえば、2003/200301〜200312と、2004/200401〜2004/200404まで変換したい場合は次のようになるかな。
<pre>
for y in 3 4
do
for m in 01 02 03 04 05 06 07 08 09 10 11 12
do
./t2m.pl -d 200${y}/200${y}${m}.td >> log2mt.log
done
done
</pre>

<hr>
<P><b>蛇足2(movabletype2blogger)</b></P>
<p>
<a href="http://www.blogger.com/home" target="_blank">blogger</a>にもインポートしてみたい、という欲求から調べてみました。
ないなら作るか、と思いましたが、ちゃんと作ってくれていました。これだけメジャーなものなら誰かしら用意してくれているんですね。ありがたい。</p>
<p>
時々紹介されるのは、convertしてくれる<a href="http://movabletype2blogger.appspot.com/" target="_blank">このwebページ</a>ですが、1回に変換できるのは1Mまで。
まどろっこしいので、一気に全部変換してくれるのはないのか？ということで、Linux上で変換することにします。
</p><p>
さっきのページの<a href="http://code.google.com/p/google-blog-converters-appengine/" target="_blank">元ネタのページ</a>から、tar.gzをダウンロードします。
</p><p>
so-netからエクスポートしたMTフォーマットのファイルは、日付の付け方が今ひとつなので、そこだけ少し改良してbloggerのxml形式に変更です。<br>
(so-netのblogでエクスポートすると、「11:00:00 PM」という形式ではなく、「23:00:00」という形式で出てしまいます。そのフォーマットにも対応できるように変更)
</p>
<pre>
$ cd google-blog-converters-r89/src/movabletype2blogger/
[movabletype2blogger]$ diff mt2b.py mt2b.py.org
312,315c312
<       try:
<         return time.strptime(mt_time, "%m/%d/%Y %H:%M:%S")
<       except ValueError:
<         return time.gmtime()
---
>       return time.gmtime()
</pre>
