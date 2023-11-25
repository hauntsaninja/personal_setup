import numpy as np

n = int(x)
j = json.loads(stdin)
f = x.split()
# like f, but returns None if index is of bounds
ff = defaultdict(lambda: None, dict(enumerate(x.split())))

d = defaultdict(list)
c = Counter()
