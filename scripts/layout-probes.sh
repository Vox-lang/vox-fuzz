#!/bin/bash
# The Step-1 probe set for the layout randomiser: what vox actually does
# with whitespace. Writes every probe into vf_scratch/layout-probes/,
# compiles and runs each one, and records the compiler's verdict, the exit
# status and the stdout in a header comment at the top of the probe and in
# a sibling <name>.result file.
#
# It rebuilds the whole set from scratch every time on purpose:
# ./test.sh sweeps ./vf_* from the repo root after every test, so the probe
# directory is not durable. This script is.
set -u
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[[ -n "${1:-}" ]] && ROOT="$1"
D="$ROOT/vf_scratch/layout-probes"
rm -rf "$D"; mkdir -p "$D"; cd "$D" || exit 1
VOX="${VOX:-/home/josj/scr/english/vox/target/release/vox}"
export VOX_CORE_PATH="${VOX_CORE_PATH:-/home/josj/scr/english/vox/coreasm}"

p() { printf '%b' "$2" > "$1.vox"; }

# --- a newline in the middle of a sentence -------------------------------
p 010_newline_midsentence            'a number\ncalled x\nis 5.\nPrint x.\n'
p 011_newline_in_while_header        'a number called x is 0.\nWhile x is\nless\nthan 3, increment x.\nPrint x.\n'
p 012_newline_between_comma_actions  'a number called x is 0.\nWhile x is less than 3, print x,\nincrement x.\nPrint "done".\n'
# --- tabs -----------------------------------------------------------------
p 020_tabs_indent                    'To ping.\n\tPrint "pong".\n\nping.\n'
p 021_tab_as_separator               'a number\tcalled\tx\tis\t5.\nPrint x.\n'
p 022_tab_at_line_start              '\ta number called x is 5.\n \t \tPrint x.\n'
# --- no whitespace at all -------------------------------------------------
p 030_zero_space_after_period        'Print "a".Print "b".\n'
p 031_fully_minified                 'a number called x is 0.While x is less than 3,increment x.Print x.\n'
# --- much whitespace ------------------------------------------------------
p 040_many_spaces                    'a         number     called      x        is        5.\nPrint                                                        x.\n'
p 041_trailing_whitespace            'a number called x is 5.   \nPrint x.\t\t\n'
# --- is a whitespace-only line a paragraph break? -------------------------
p 042_spaces_only_line_in_body       'To ping.\n    Print "pong".\n    \nping.\n'
p 043_tab_only_line_in_body          'To ping.\n    Print "pong".\n\t\nping.\n'
p 044_empty_line_in_body_control     'To ping.\n    Print "pong".\n\nping.\n'
p 045_no_blank_line_control          'To ping.\n    Print "pong".\nping.\n'
# --- how many blank lines is one paragraph break? -------------------------
p 050_two_blank_lines                'To ping.\n    Print "pong".\n\n\nping.\n'
p 051_three_blank_lines              'To ping.\n    Print "pong".\n\n\n\nping.\n'
p 052_five_blank_lines               'To ping.\n    Print "pong".\n\n\n\n\n\nping.\n'
# --- does a blank line force-close an open clause? ------------------------
p 053_blank_after_while_dangling_comma    'a number called x is 0.\nWhile x is less than 3, increment x,\n\nPrint "after".\nPrint x.\n'
p 054_blank_line_after_if_header           'a number called n is 2.\nIf n is equal to 1 then,\n\nPrint "closed".\n'
p 055_blank_after_for_each_dangling_comma  'a number called x is 0.\nFor each number from 1 to 3, increment x,\n\nPrint "after".\nPrint x.\n'
p 056_blank_after_repeat_dangling_comma    'a number called x is 0.\nRepeat 3 times, increment x,\n\nPrint "after".\nPrint x.\n'
p 057_blank_after_while_period             'a number called x is 0.\nWhile x is less than 3,\n    If x is less than 9 then, increment x.\n\nPrint "after".\nPrint x.\n'
# --- the two ends of the file ---------------------------------------------
p 060_leading_blank_lines            '\n\n\nPrint "hello".\n'
p 061_no_trailing_newline            'Print "hello".'
p 062_trailing_blank_lines           'Print "hello".\n\n\n\n'
# --- a newline right after a clause opener --------------------------------
p 070_newline_after_then             'a number called n is 1.\nIf n is equal to 1 then,\nPrint "yes".\nPrint "after".\n'
p 071_newline_after_otherwise        'a number called n is 2.\nIf n is equal to 1 then,\nPrint "yes".\nOtherwise,\nPrint "no".\nPrint "after".\n'
# --- string literals are data, not layout ---------------------------------
p 080_newline_inside_string          'Print "a\nb".\n'
p 081_escaped_quote_in_string        'Print "a".\nPrint "escaped \\"quoted\\" text".\n'
p 082_paren_inside_string            'Print "a (b".\nPrint "c) d".\n'
# --- comments --------------------------------------------------------------
p 090_newline_inside_comment         '(a comment\nspanning\nlines)\nPrint "hi".\n'
p 091_nested_comment                 '(outer (inner (deep)) tail)\nPrint "hi".\n'
p 092_comment_between_tokens         'a number (mid-sentence comment) called x is 5.\nPrint x.\n'
p 093_quote_inside_comment           '(a comment with a " quote in it)\nPrint "hi".\n'
p 094_blank_line_inside_comment      'To ping.\n    Print "pong".\n(a comment\n\nwith a blank line inside)\nping.\n'
p 095_zero_space_around_comment      'a number(c)called x is 5.\nPrint x.\n'
p 096_comment_flush_between_statements 'Print "a".(c)Print "b".\n'
# --- where may a gap shrink to nothing? -----------------------------------
p 097_zero_space_before_string       'Print"a".\nPrint "b".\n'
p 098_space_before_period            'a number called x is 5.\nPrint "x is {x}"    .\n'
p 099_space_before_comma             'a number called x is 0.\nWhile x is less than 3 , increment x .\nPrint x.\n'
p 100_zero_space_after_string        'a text called t is "v1".\nIf t is not "v1"then, Exit 91.\nPrint "ok".\n'
p 101_list_bracket_spacing           'a list called l is [ 1 , 2 , 3 ].\nPrint l.\na list called m is[4,5].\nPrint m.\n'
p 102_joined_words_must_fail         'Printx.\n'
p 103_space_between_word_and_period  'a number called x is 5.\nPrint x .\n'
p 104_brace_group_spacing            'a number called x is 20.\na number called y is 6.\nPrint { x add y }multiply 3.\nPrint {x add y}   multiply 3.\n'
p 105_map_literal_spacing            'a map called m is{"a":1,"b":2}.\nPrint m.\na map called n is { "a" : 1 , "b" : 2 }.\nPrint n.\n'
p 106_format_string_untouched        'a number called x is 5.\nPrint "v {x}".\na text called t is "x is {x}"   .\nPrint t.\n'
# --- a single-quoted name is not layout -----------------------------------
p 110_quoted_name_control            "To 'made at'.\n    Print \"made\".\n\n'made at'.\n"
p 111_quoted_name_ws_changed         "To 'made\tat'.\n    Print \"made\".\n\n'made at'.\n"
p 112_possessive_apostrophe          "a number called x is 5.\nPrint arguments's count.\nPrint x.\n"
# --- minified definitions --------------------------------------------------
p 113_function_minified              'To f2 with a number called p1.a number called r is p1 add 26.Return a number, r.\n\nPrint f2 of 4.\n'
p 114_thing_minified                 "A thing called t1 has a number called x1 is 0,a number called x2 is 0.\n\na t1 called i1.\nSet i1's x1 to 7.\nPrint i1's x1.\n"
# --- the four places a newline is NOT cosmetic on vox 0.4.7 ---------------
p 120_equal_to_split_by_newline      'a number called x is 0.\nIf x is less than or equal\nto 0 then, Print "yes".\n'
p 121_equal_to_split_by_spaces       'a number called x is 0.\nIf x is less than or equal    to 0 then, Print "yes".\n'
p 122_value_called_split_by_newline  'a value\ncalled v is "x".\nPrint v.\n'
p 123_value_called_split_by_spaces   'a value    called v is "x".\nPrint v.\n'
p 124_thing_call_with_split_by_newline "A thing called t4 has\n    a function called 'made at',\n    a number called x1 is 0.\n\nTo do the t4's 'made at', with a number called x1.\n    a t4 called plotted.\n    Set plotted's x1 to x1.\n    Return a t4, plotted.\n\na t4 called i1 is a t4's 'made at'\nwith 101.\nPrint i1's x1.\n"
p 125_thing_call_with_split_by_spaces  "A thing called t4 has\n    a function called 'made at',\n    a number called x1 is 0.\n\nTo do the t4's 'made at', with a number called x1.\n    a t4 called plotted.\n    Set plotted's x1 to x1.\n    Return a t4, plotted.\n\na t4 called i1 is a t4's 'made at'  with 101.\nPrint i1's x1.\n"
p 126_possessive_flush_against_string  'a map called m1 is {"count": 7}.\nPrint m1'"'"'s"count". Print m1'"'"'s "count".\n'
p 127_possessive_spaced_from_string    'a map called m1 is {"count": 7}.\nPrint m1'"'"'s "count". Print m1'"'"'s "count".\n'
p 128_possessive_flush_own_line        'a map called m1 is {"count": 7}.\nPrint m1'"'"'s"count".\nPrint m1'"'"'s "count".\n'
# --- the one-byte staging buffer the pass is built on ---------------------
p 130_set_byte_on_fresh_fixed_buffer 'a buffer called one is 1 bytes in size.\nSet byte 1 of one to 65.\nPrint "length {one'"'"'s length} content {one as text}".\na buffer called out.\nappend one to out.\nSet byte 1 of one to 66.\nappend one to out.\nPrint "out {out as text} length {out'"'"'s length}".\n'

# --- run every probe and record what happened ----------------------------
W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT
record() {
for f in $(ls *.vox | sort); do
    n="${f%.vox}"
    {
        if "$VOX" "$f" -o "$W/$n" > "$W/$n.cerr" 2>&1; then
            echo "compile: OK"
            sed 's/\x1b\[[0-9;]*m//g; s/^/compiler-said: /' "$W/$n.cerr"
            "$W/$n" > "$W/$n.out" 2>&1
            echo "exit: $?"
            echo "stdout:"
            sed 's/^/| /' "$W/$n.out"
        else
            echo "compile: REJECTED"
            sed 's/\x1b\[[0-9;]*m//g; s/^/| /' "$W/$n.cerr"
        fi
    } > "$n.result" 2>&1
done
}
record

# Put each probe's own recorded output at the top of it, as a comment.
# Skipped where a header would change what the probe is asking (what is at
# the very start or the very end of the file) or where the recorded text
# holds unbalanced parentheses, which a Vox comment cannot carry.
python3 - <<'PY'
import glob
positional={'060_leading_blank_lines','061_no_trailing_newline','062_trailing_blank_lines'}
skipped=[]
for f in sorted(glob.glob('*.vox')):
    n=f[:-4]
    if n in positional:
        skipped.append(n+' (asks about the start or end of the file)'); continue
    body='\n'.join(' '+l for l in open(n+'.result').read().rstrip('\n').split('\n'))
    if body.count('(')!=body.count(')'):
        skipped.append(n+' (recorded output has unbalanced parentheses)'); continue
    hdr=('(Recorded against vox 0.4.7 - what the compiler actually did with\n'
         ' the program below:\n'+body+')\n')
    body_text=open(f).read()
    open(f,'w').write(hdr+body_text)
for s in skipped:
    print('header not embedded in', s)
PY

# A leading comment must not change what a probe does. Re-run the whole
# set now that the headers are in, and say so out loud if any verdict
# moved. The .result files end up describing the files as they now stand,
# so the only thing that differs from a header is the line number inside a
# diagnostic, which the header itself pushed down.
for f in *.vox; do cp "${f%.vox}.result" "$W/${f%.vox}.before"; done
record
changed=0
for f in *.vox; do
    n="${f%.vox}"
    before=$(grep -a -v -e "-->" -e "^compiler-said: *[0-9 ]*|" -e "^| *[0-9 ]*|" -e "\^--- here" "$W/$n.before")
    after=$(grep -a -v -e "-->" -e "^compiler-said: *[0-9 ]*|" -e "^| *[0-9 ]*|" -e "\^--- here" "$n.result")
    if [[ "$before" != "$after" ]]; then echo "VERDICT MOVED after embedding the header: $n"; changed=1; fi
done
[[ $changed == 0 ]] && echo "every probe verdict survived its own header comment"
# Keep the pre-header recording as the canonical .result, so a probe's
# sibling file and its own header comment say exactly the same thing and
# the line numbers in a diagnostic point at the probe rather than at the
# header the diagnostic was recorded before.
for f in *.vox; do cp "$W/${f%.vox}.before" "${f%.vox}.result"; done
echo "probes: $(ls *.vox | wc -l) in $D"
