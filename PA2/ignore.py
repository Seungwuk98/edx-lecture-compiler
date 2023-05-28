import sys

while True:
    inp = input()
    st = ''
    for x in inp:
        st += f'{{{x}}}'
    print(st)