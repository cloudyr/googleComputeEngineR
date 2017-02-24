#!/bin/bash
echo "Checking for CUDA and installing."
# Check for CUDA, try to install until successful.
if ! rpm -q  cuda; then
  curl -O http://developer.download.nvidia.com/compute/cuda/repos/rhel7/x86_64/cuda-repo-rhel7-8.0.44-1.x86_64.rpm
  rpm -i --force ./cuda-repo-rhel7-8.0.44-1.x86_64.rpm
  yum clean all
  yum install epel-release -y
  yum update -y
  yum install cuda -y
  yum install pciutils -y
fi
