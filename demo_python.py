#!/usr/bin/env python3
"""
Sample Python module for CI workflow demonstration.
This file is created to support the GitHub Actions CI workflow
even though this is primarily a Flutter project.
"""


def hello_world():
    """Simple function for demonstration purposes."""
    return "Hello, World from Python CI!"


def add_numbers(a, b):
    """Add two numbers and return the result."""
    return a + b


if __name__ == "__main__":
    print(hello_world())
    print(f"2 + 3 = {add_numbers(2, 3)}")
