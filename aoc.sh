create() {
    day=$(day $1)
    touch "src/${day}.zig"
    touch "samples/${day}.txt"
    touch "inputs/${day}.txt"
}

day() {
  echo ${1:-$(date "+%d")}
}

bench() {
  day="$(day $1)"
  if [ -n "$1" ]; then
    shift
  fi
  zig build install_day$day -Drepeats=1000 -Dtarget=native --release=fast && \
    echo "-N $@ \"zig-out/bin/day$day inputs/$day.txt\"" && \
    hyperfine -N $@ "zig-out/bin/day$day inputs/$day.txt"
}

r() {
  zig build day$(day $1) -- inputs/$(day $1).txt
}

rs() {
    zig build day$(day $1) -- samples/$(day $1).txt
}

br() {
    zig build install_day$(day $1) -Dtarget=native --release=fast
}

rrs() {
    zig build day$(day $1) -Dtarget=native --release=fast -- samples/$(day $1).txt
}

rr() {
    zig build day$(day $1) -Dtarget=native --release=fast -- inputs/$(day $1).txt
}
