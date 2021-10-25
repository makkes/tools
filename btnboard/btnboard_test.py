import unittest
from btnboard import run

class MockSerial:
    def __init__(self, lines):
        self.lines = lines

    def readline(self):
        if len(self.lines) > 0:
            return self.lines.pop(0)
        return b'EOS' 

class TestRun(unittest.TestCase):

    def test_happy_path(self):
        out = ""
        def cb():
            nonlocal out
            out = "called"
        run(MockSerial([b'FE']), 10, [cb])
        self.assertEqual(out, "called")

    def test_longer_press(self):
        out = ""
        def cb():
            nonlocal out
            out += "+"
        run(MockSerial([b'FE', b'FE', b'FE', b'FE']), 10, [cb])
        self.assertEqual(out, "+")

    def test_two_presses(self):
        """Pressing a button while the callback
        is running will lead to the button press
        be captured after the callback has returned.
        """
        out = ""
        def cb():
            nonlocal out
            out += "+"
        run(MockSerial([b'FE', b'FE', b'FF', b'FE', b'FE', b'FF']), 10, [cb])
        self.assertEqual(out, "++")

    def test_parallel_press(self):
        out = [0, 0]
        def cb(idx):
            def cb_idx():
                nonlocal out
                out[idx] += 1
            return cb_idx
        run(MockSerial([b'FC']), 10, [cb(0), cb(1)])
        self.assertEqual(out, [1, 1])

if __name__ == "__main__":
    unittest.main()
