#!/usr/bin/env python3

def main():
    print("Hello from Python!")
    
    # Simple Python example
    numbers = [1, 2, 3, 4, 5]
    total = sum(numbers)
    
    print(f"The sum of {numbers} is: {total}")
    
    # Function example
    greet("World")

def greet(name):
    print(f"Hello, {name}! Welcome to CodeLab IDE.")

class Calculator:
    def add(self, a, b):
        return a + b
    
    def subtract(self, a, b):
        return a - b
    
    def multiply(self, a, b):
        return a * b
    
    def divide(self, a, b):
        return a / b

if __name__ == "__main__":
    main()
