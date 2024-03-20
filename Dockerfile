##########################################################################
# tapis image for documentation
#
# usage:
#   docker build -f ./Dockerfile -t tapis/tapis-documentation .
#
#   $TAG            tapis/tapis-documentation
#
#   Tested with Docker version 18.06.0-ce
##########################################################################
# FROM rackspacedot/python37:latest
FROM python:3.9

RUN mkdir /workspace
RUN pip install --upgrade pip

WORKDIR /workspace

EXPOSE 7898

# Launch python
CMD bash