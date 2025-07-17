"""
Test file for demo_python.py
This demonstrates the pytest functionality in the CI workflow.
"""

import pytest
from demo_python import hello_world, add_numbers


def test_hello_world():
    """Test the hello_world function."""
    result = hello_world()
    assert result == "Hello, World from Python CI!"
    assert isinstance(result, str)


def test_add_numbers():
    """Test the add_numbers function."""
    assert add_numbers(2, 3) == 5
    assert add_numbers(0, 0) == 0
    assert add_numbers(-1, 1) == 0
    assert add_numbers(10, -5) == 5


def test_add_numbers_types():
    """Test add_numbers with different number types."""
    assert add_numbers(2.5, 1.5) == 4.0
    assert add_numbers(1, 2.0) == 3.0


if __name__ == "__main__":
    pytest.main([__file__])
