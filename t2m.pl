#!/usr/bin/perl

# 前提知識
#  tdiaryのログはdata_pathの下にファイルがあります。
#  ファイル
#   200405.td2 : 日記ファイルのデータ本体
#   200405.tdc : ツッコミデータ ( TrackBackデータも存在 )
#
# 使いかた
#  上記データファイルがカレントディレクトリにある時だけ、動作確認をしています。
#
#  t2m.pl -d [log file] {-n [date]}  {-g}
#   [log file]は、最後の文字(2やc)を除いたファイル名を指定。
#   200405.tdc, 200405.td2の場合は, 200405.tdを指定
#
#   [date] この日付けを指定し、これよりも新しい日付けの日記にたいして処理を行わせる
#    書式例: 20040101
#

$author="ks";

#画像の移行を行うばあいは設定必須
${tdiary_imags_dir}="/home/kenstar/public_html/tdiary/images";
${MT_image_dir}="/home/kenstar/public_html/ks/archives";
${image_url}="/~kenstar/ks/archives";

use Getopt::Std;
use File::Copy;

getopt("d:n:g");

#---------------------------
# log2mt.logの本体部分出力
#---------------------------
sub print_body($$$){
    my($title, $date, $body, $category)=@_;
    print << "__DIARY_FST__";
AUTHOR: $author
TITLE: $title
STATUS: Publish
ALLOW COMMENTS: 1
CONVERT BREAKS: __default__
ALLOW PINGS: 1
__DIARY_FST__

if($category ne ""){
    print << "__DIARY_CATEGORY__";
PRIMARY CATEGORY: $category
CATEGORY: $category
__DIARY_CATEGORY__
}else{
    print "PRIMARY CATEGORY: \n";
}
print << "__DIARY_SND__";

DATE: $date
-----
BODY:
$body
-----
EXTENDED BODY:

-----
EXCERPT:

-----
KEYWORDS:

-----
__DIARY_SND__
}

#------------------------------
# log2mt.logのコメント部分出力
#------------------------------
sub print_comment($$$$$$){
    my($com_auth, $email, $date, $body, $ip, $url)=@_;
    print << "__COMMENT__";
COMMENT:
AUTHOR: $com_auth
EMAIL: $email
IP: $ip
URL: $url
DATE: $date
$body

-----
__COMMENT__
}

#---------------------------------
# log2mt.logのTrackBack部分出力
#---------------------------------
sub print_ping($$$$$$){
    my($title, $url, $blog_name, $date, $body, $ip)=@_;
    print << "__PING__";

PING:
TITLE: $title
URL: $url
IP: $ip
BLOG NAME: $blog_name
DATE: $date
$body

-----
__PING__
}

sub print_end{
    print "\n\n--------\n";
}


#------------------------------
# td2の読み込み。
#------------------------------
# 使用するkey
# $diary_key = "${date}-${key}"

# === つかうHash
# $title{$diary_key}
# $date{$diary_key}
# $body{$diary_key}
sub read_tdiary($){
    my ($file) = @_;

    open TDIARY, $file;
    $title_switch=0;

    while (<TDIARY>){
	chomp;
	if(/^.$/){
	    # 日付終了記号
	    $title_switch=0;
	}elsif(/^$/){
	    # 空の行。次の行はTitle
	    $title_switch=1;
	}elsif(/^Format: tDiary$/){
	    # 意味無の行。ただし、Headerのさいご
	    $title_switch=2;
	}elsif($title_switch==2){
	    # Headerの次のぎょうは空行。何もしない。
	    $title_switch=1;
	}elsif(/Date: ([\w]+)/){
	    # 日付けを読み込む。
	    if($date == $1){
		$key++;
	    }else{
		$key=0;
	    }
	    $date = $1;
	    $diary_key = "${date}-${key}";
	    $date =~/([\d][\d][\d][\d])([\w][\w])([\w][\w])/;
	    my($year, $mon, $day);
	    $year = $1;
	    $mon = $2;
	    $day = $3;
	    
	    # MTの日付け書式に変換
	    $p_date = sprintf "%02d/%02d/%02d", ${mon}, ${day}, ${year};
	}elsif(/Title: (.*)/){
#	    $title{$diary_key}=$1;
	}elsif(/Last-Modified/){
	    # 無視
	}elsif(/^Visible: (.*)/){
	    if($1 =~ /true/){
		$visible=1;
	    }else{
		$visible=0;
	    }
	    # 無視
	}elsif($title_switch==1){
	    # 空行の次だったのでタイトルとして使用
	    $key++;
	    $diary_key = "${date}-${key}";

	    my($tmp);
	    $tmp = $_;
	    if ($tmp =~ /\[([^\]]*)\](.*)/){
		$category{$diary_key} = $1;
	        $title{$diary_key} = $2;
		$visible{$diary_key} = $visible;
	    }else{
		$category{$diary_key} = "";
	        $title{$diary_key} = $tmp;
		$visible{$diary_key} = $visible;
	    }
	    $title_switch=0;
	    $p_date_time = sprintf "%s 01:00:%02d PM", ${p_date}, ${key};
	    $date{$diary_key}=$p_date_time;
	}else{
	    # 日記本体
	    #  <%=image 0, '川べり　ここに写ってないけど、久々にすずめをみたよ。', nil, [256,192]%>
	    #  <%=image 1, '職場からの東京(昼)その1'%>
	    # for 画像対応
	    # 20040413_0.jpg
	    if (/\<\%=image\s+([\d]+),\s*'(.*)'\s*(,\s*([^\[]*)\s*,\s*(.*)\s*)?\%\>/ ){
		print "image\n" if $DEBUG;
	        print "$1, $2, $3,$4,\n" if $DEBUG;
	        $image_key = $1;
                $alt = $2;
                $op = $3;
                $nil = $4;
                $wh = $5;

	        $image_name ="${date}_${image_key}.jpg";
	        print "$image_name\n" if $DEBUG;

		if($wh ne ""){
		    $wh =~ /\[\s*([\d]+)\s*,\s*([\d]+)\s*\]/;
		    $width = $1;
		    $height = $2;
		}else{
		    $width=-1;
		    $height=-1;
		}

	        s/\<\%=image\s+[\d]+,\s*'.*'\s*(,\s*.*\s*,\s*.*\s*)?\%\>/\<img alt=\"${alt}\" src=\"${image_url}\/${image_name}\" width=${width} height=${height} border="0"\/>/;
	        copy ("${tdiary_imags_dir}/${image_name}", "${MT_image_dir}") or print "cannot copy\n";
	    }
	    $body{$diary_key} .= $_ . "\n";
	}
    }
    close TDIARY;
}


#--------------------------------------------------------------
# commnet,trackback読み込み
#--------------------------------------------------------------
# comment部分とtrackbackは同じ書式で記録されているので共通。
#
# commentの日付については、Last-Modifiedのデータを使用する。
# 読み取りデータ
# 使用するkey
#  $c_diary_key = "${c_date}-${c_key}-C"

# ==== つかうHash
# $c_track{$c_diary_key} 
# $c_author{$c_diary_key}
# $c_mail{$c_diary_key}
# $c_date{$c_diary_key}
# $c_body{$c_diary_key}

#track back用
# $c_url{$c_diary_key}
# $c_blog_name{$c_diary_key}
# $c_ping_title{$c_diary_key}
# $c_ping_body{$c_diary_key}

sub read_comment($){
    my($file)=@_;
    print "$file\n" if $DEBUG;
    open TDIARY_COMMENT, $file;

    while (<TDIARY_COMMENT>){
	chomp;
	if(/TDIARY2.00.00/){
	}elsif(/^.$/){
	    # 日付終了記号
	}elsif(/^$/){
	    # 空の行。
	}elsif(/^Format: tDiary$/){
	    # 意味無の行。ただし、Headerの最後
	}elsif($c_title_switch==2){
	    # Headerの次のぎょうは空行。何もしない。
	}elsif(/Date: ([\w]+)/){
	    # 日付けを読み込む。
	    $track_back=0;
	    if($c_date == $1){
		$c_key++;
	    }else{
		$c_key=1;
	    }
	    $c_date = $1;
	    $c_diary_key = "${c_date}-${c_key}-C";

            # コメントと日付けの紐づけを間単にする。
            $diary_key = "${c_date}-1";
            $comments{$diary_key} .= $c_diary_key . ":";

	}elsif(/Name: (.*)/){
	    $name = $1;

	    if ( $name eq "TrackBack" ){
		$track_back=1;
		$c_track{$c_diary_key} = 1;
	    }else{
		$track_back=0;
		$read_ping_body=0;
		$c_track{$c_diary_key} = 0;
	    }
	    $c_author{$c_diary_key} = $name;

	}elsif(/Mail: (.*)/){
	    $c_mail{$c_diary_key} = $1;
	}elsif(/Last-Modified: ([\w]+)/){
	    my($my_dt);
	    $my_dt = $1;
	    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($my_dt);
	    $mon++;
	    $year+=1900;
	    if ($hour > 11 ){
		$ampm="PM";
		$hour -=11;
	    }else{
		$ampm="AM";
	    }
	    #$c_p_date= "$wday/$mon/$year $hour:$min:$sec $ampm";
	    $c_p_date= sprintf "%02d/%02d/%04d %02d:%02d:%02d %s", $mon, $wday, $year, $hour, $min, $sec, $ampm;

	    $c_date{$c_diary_key}=$c_p_date;	
	}elsif(/^Visible: (.*)/){
	    if($1 =~ "true"){
		$c_visible{$c_diary_key}=1;
	    }else{
		$c_visible{$c_diary_key}=0;
	    }
	    print "C $c_visible{$c_diary_key}" if $DEBUG;
	}else{
	    # 日記本体
	    # TrackBackのため条件分岐

	    if($track_back==1){
		if(/http:/){
		    $c_url{$c_diary_key} = $_;
		    $read_blog_switch=1;
		}elsif($read_blog_switch==1){
		    $c_blog_name{$c_diary_key}=$_;
		    $read_blog_switch=0;
		    $read_ping_title=1;
		}elsif($read_ping_title==1){
		    $c_ping_title{$c_diary_key}=$_;
		    $read_ping_title=0;
		    $read_ping_body=1;
		}elsif($read_ping_body==1){
		    $c_ping_body{$c_diary_key} .= $_;
		}
	    }else{
		$c_body{$c_diary_key} .= $_ . "\n";
	    }
	}
    }
    close TDIARY;

}

#========#
#  Main  #
#========#

# 日記読み込み
# check options
if ($opt_d eq ""){
    print "usage t2m.pl -d [log file] (without c, or 2)\n";
    print "  example Target file 200405.td2, 200405.tdc   then [log file] is 200405.td\n";
    exit 1;
}

print "$opt_d\n" if $DEBUG;
&read_tdiary("${opt_d}2");
&read_comment("${opt_d}c");


if ($opt_n){
    if ($opt_n !~ /^[\d]{8}$/){
	print "-n は、20040101のように日付指定してください。\n";
	exit 1;
    }

    my($check)=0;
    for $key ( sort keys %title){
	if($check==1){
	    push @target_list, $key;
	}else{
	    my($tmp_date) = split(/-/,$key);
	    if( $tmp_date >= $opt_n ){
		print "match\n";
		$check=1;
		push @target_list, $key;
	    }
	}
    }
}else{
    @target_list = sort keys %title;
}

for $key ( @target_list ){
    print "D $key : $title{$key}\n" if $DEBUG2;
    print "D $date{$key}\n" if $DEBUG2;
    print "D $body{$key}\n" if $DEBUG2;
    if($visible{$key}==1){
	&print_body($title{$key}, $date{$key}, $body{$key}, $category{$key});


	# print つっこみ
	my (@comments) = split(":", $comments{$key});
	for $c_key(@comments){
	    if($c_visible{$c_key}==1){
		if($c_track{$c_key} == 0){
		    &print_comment($c_author{$c_key}, $c_mail{$c_key}, $c_date{$c_key}, $c_body{$c_key}, "","" );
#	        &print_comment($c_author{$c_key}, $c_mail{$c_key}, $c_date{$c_key}, $c_body{$c_key}, $c_ip{$c_key},$c_url{$c_key} );
		}else{
		    &print_ping($c_ping_title{$c_key}, $c_url{$c_key}, $c_blog_name{$c_key}, $c_date{$c_key}, $c_ping_body{$c_key}, "");
		}
	    }
	    print "D $c_key : $c_author{$c_key} : $c_mail{$c_key} : $c_date{$c_key}\n" if $DEBUG2;
	    print "D $c_body{$c_key}\n" if $DEBUG2;
	}
	&print_end();
    }
}
