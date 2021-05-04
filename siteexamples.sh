#/bin/sh

cd examples

for i in *.v
do
  coqdoc -s --no-lib-name -parse-comments --no-index --utf8 --interpolate --html \
      --external http://github.com/mattam82/Coq-Equations/tree/master Equations \
      -Q ../theories Equations -R . Examples -d ../doc/examples $i
done

cd ..

git checkout doc/examples/coqdoc.css
