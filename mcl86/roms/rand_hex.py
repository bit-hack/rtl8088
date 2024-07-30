import random

with open('out.hex', 'w') as fd:
  for i in range(16 * 1024):
    if i and (i % 32) == 0:
      fd.write('\n')
    byte = random.randint(0, 255)
    fd.write('{:02x} '.format(byte))
