./icefront/icefront.py -o iceXt.bin -t iceXt -s 25 iceXt rtl/iceXt.f | tee build.log
grep -rn -E "Warning|Error" build.log
read FOOBAR
