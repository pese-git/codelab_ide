void main() {
  print('Hello from CodeLab IDE!');
  
  // Simple example to demonstrate the IDE
  var numbers = [1, 2, 3, 4, 5];
  var sum = numbers.reduce((a, b) => a + b);
  
  print('The sum of $numbers is: $sum');
  
  // Function example
  greet('World');
}

void greet(String name) {
  print('Hello, $name! Welcome to CodeLab IDE.');
}

class Calculator {
  int add(int a, int b) => a + b;
  int subtract(int a, int b) => a - b;
  int multiply(int a, int b) => a * b;
  double divide(int a, int b) => a / b;
}
