import logging

logging.basicConfig(format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',filename='example.log', encoding='utf-8', level=logging.DEBUG)

logging.info('Store input numbers')
num1 = input('Enter first number: ')
num2 = input('Enter second number: ')

logging.debug('First number entered: %s', num1)
logging.debug('Second number entered: %s', num2)

logging.info('Add two numbers')
sum = float(num1) + float(num2)

logging.debug('Sum of the two numbers: %d', sum)

logging.info('Displaying the sum')
msg = 'The sum of {0} and {1} is {2}'.format(num1, num2, sum)

logging.debug('Rendered message: %s', msg)

print(msg)