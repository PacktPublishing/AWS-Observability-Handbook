# AWS Observability Handbook

<a href="https://www.packtpub.com/product/aws-observability-handbook/9781804616710#_ga=2.105056963.1567041631.1682686735-2056229400.1667224110?utm_source=github&utm_medium=repository&utm_campaign=9781801076012"><img src="https://content.packt.com/B18969/cover_image_small.jpg" alt="AWS Observability Handbook" height="256px" align="right"></a>

This is the code repository for [AWS Observability Handbook](https://www.packtpub.com/product/aws-observability-handbook/9781804616710#_ga=2.105056963.1567041631.1682686735-2056229400.1667224110?utm_source=github&utm_medium=repository&utm_campaign=9781801076012), published by Packt.

**Monitor, trace, and alert your cloud applications with AWS’ myriad observability tools**

## What is this book about?

This book covers the following exciting features:
* Capture metrics from an EC2 instance and visualize them on a dashboard
* Conduct distributed tracing using AWS X-Ray
* Derive operational metrics and set up alerting using CloudWatch
* Achieve observability of containerized applications in ECS and EKS
* Explore the practical implementation of observability for AWS Lambda
* Observe your applications using Amazon managed Prometheus, Grafana, and OpenSearch services
* Gain insights into operational data using ML services on AWS
* Understand the role of observability in the cloud adoption framework

If you feel this book is for you, get your [copy](https://www.amazon.com/dp/1804616710) today!

<a href="https://www.packtpub.com/?utm_source=github&utm_medium=banner&utm_campaign=GitHubBanner"><img src="https://raw.githubusercontent.com/PacktPublishing/GitHub/master/GitHub.png" 
alt="https://www.packtpub.com/" border="5" /></a>

## Instructions and Navigations
All of the code is organized into folders. For example, Chapter07.

The code will look like the following:
```
 Function:
   Runtime: nodejs16.x
   Timeout: 100
   Layers:
     - !Sub "arn:aws:lambda:${AWS::Region}:580247275435:layer:LambdaInsightsExtension:21"
   TracingConfig:
       Mode: Active
```

**Following is what you need for this book:**
This book is for SREs, DevOps and cloud engineers, and developers who are looking to achieve their observability targets using AWS native services and open source managed services on AWS. It will assist solution architects in achieving operational excellence by implementing cloud observability solutions for their workloads. Basic understanding of AWS cloud fundamentals and different AWS cloud services used to run applications such as EC2, container solutions such as ECS, and EKS will be helpful when using this book.

With the following software and hardware list you can run all code files present in the book (Chapter 1-15).
### Software and Hardware List
| Chapter | Software required | OS required |
| -------- | ------------------------------------ | ----------------------------------- |
| 1-15 | Python 3.9 | Windows, Mac OS X, and Linux (Any) |
| 1-15 | Node.js 14/Node.js 16 | Windows, Mac OS X, and Linux (Any) |
| 1-15 | JSON | Windows, Mac OS X, and Linux (Any) |

We also provide a PDF file that has color images of the screenshots/diagrams used in this book. [Click here to download it](https://packt.link/n7E68).

### Related products
* AWS FinOps Simplified [[Packt]](https://www.packtpub.com/product/aws-finops-simplified/9781803247236?utm_source=github&utm_medium=repository&utm_campaign=9781803247236) [[Amazon]](https://www.amazon.com/dp/1803247231)

* Cloud-Native Observability with OpenTelemetry [[Packt]](https://www.packtpub.com/product/cloud-native-observability-with-opentelemetry/9781801077705?utm_source=github&utm_medium=repository&utm_campaign=9781801077705) [[Amazon]](https://www.amazon.com/dp/1801077703)


## Get to Know the Author
**Phani Kumar Lingamallu**
works as a senior partner solution architect at Amazon Web Services (AWS). With around 19 years of IT experience, he previously served as a consultant for several well-known companies, such as Microsoft, HCL Technologies, and Harsco. He has worked on projects such as the large-scale migration of workloads to AWS and the Azure cloud. He has hands-on experience with the setup of monitoring/management for over 45,000 servers, and the design and implementation of large-scale AIOps transformations for clients across Europe, the US, and APAC, covering monitoring, automation, reporting, and analytics. He holds a Master of Science in electronics and possesses certifications including AWS Solution Architect Professional and Microsoft Certified Azure Solution Architect Expert.

**Fabio Braga de Oliveira**
works as a senior partner solution architect at AWS. He carries a wealth of experience from various industries – automotive, industrial, and financial services, working in the last 19 years as a software engineer/team lead/solutions architect. His professional interests range from big to small: he loves event-driven architectures, helping build complex, highly efficient systems, and also working on small devices, building devices fleet to collect data and support companies to drive new insights, using analytics techniques and machine learning. He majored in electronics and has a BS in computer science, an MBA in project management, and a series of IT certifications, among them AWS Certified Solution Architect – Professional. Nowadays, he supports AWS partners in the DACH/CEE region with application modernization (serverless and containers) and IoT workloads.

### Download a free PDF

 <i>If you have already purchased a print or Kindle version of this book, you can get a DRM-free PDF version at no cost.<br>Simply click on the link to claim your free PDF.</i>
<p align="center"> <a href="https://packt.link/free-ebook/9781804616710">https://packt.link/free-ebook/9781804616710 </a> </p>
