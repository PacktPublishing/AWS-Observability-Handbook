import logging
import structlog

logging.basicConfig(format='%(message)s',filename='example.log', encoding='utf-8', level=logging.DEBUG)

structlog.configure(
    processors=[
        structlog.stdlib.filter_by_level,
        structlog.stdlib.add_logger_name,
        structlog.stdlib.add_log_level,
        structlog.stdlib.PositionalArgumentsFormatter(),
        structlog.processors.TimeStamper(fmt="iso"),
        structlog.processors.StackInfoRenderer(),
        structlog.processors.format_exc_info,
        structlog.processors.UnicodeDecoder(),
        structlog.processors.JSONRenderer()
    ],
    wrapper_class=structlog.stdlib.BoundLogger,
    logger_factory=structlog.stdlib.LoggerFactory(),
    cache_logger_on_first_use=True,
)

log = structlog.get_logger()

num1 = input('Enter first number: ')
num2 = input('Enter second number: ')

log = log.bind(num1=num1)
log = log.bind(num2=num2)

sum = float(num1) + float(num2)

log = log.bind(sum=sum)

msg = 'The sum of {0} and {1} is {2}'.format(num1, num2, sum)

log.debug('Rendered message', msg=msg)

print(msg)