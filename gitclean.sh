#!/bin/bash
#https://www.cnblogs.com/anhiao/p/16964976.html
#https://www.jianshu.com/p/82bb353aa1ba

#order: check del push free
#if check unchange after op, u can clone in new dir to see changes

set -x

if [ $# -lt 1 ]; then
	echo "$0 check/del/free" ;
	exit 0 ;
fi
#echo "$*"


if [ $1 == "check" ]; then
	echo "check"
git rev-list --objects --all \
	| git cat-file --batch-check='%(objecttype) %(objectname) %(objectsize) %(rest)' \
	| awk '/^blob/ {print substr($0,6)}' \
	| sort --numeric-sort --key=2 \
	| cut --complement --characters=13-40 \
	| numfmt --field=2 --to=iec-i --suffix=B --padding=7 --round=nearest

	exit 0 
fi


if [ $1 == "del" ]; then
	shift
	echo "del $*"
git filter-branch -f --index-filter "git rm --cached --ignore-unmatch -rf $*" HEAD

	exit 0 
fi


if [ $1 == "push" ]; then
	shift
	echo "push $*"
	git push origin main --force

	exit 0 
fi


if [ $1 == "free" ]; then
	echo "free"
	rm -rf .git/refs/original/
	git update-ref -d refs/original/refs/heads/master
	git reflog expire --expire=now --all
	git fsck --full --unreachable
	git repack -A -d
	git gc --aggressive --prune=now

	exit 0 
fi



