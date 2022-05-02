===================
Tapis Documentation
===================
Tapis is an NSF-funded web-based API framework for securely managing computational 
workloads across infrastructure and institutions, so that experts can focus on their 
research instead of the technology needed to accomplish it.

This documentation includes a Getting Started guide - a basic introduction to 
Tapis v3 - as well as an in-depth Technical guide; see the Technical Guide - 
Overview or you can browse directly to the section of interest. All Tapis APIs are 
defined using the OpenAPI v3 `specification <https://github.com/OAI/OpenAPI-Specification/blob/main/versions/3.0.0.md>`_. 

Quickstart
----------
This repository contains the source of the documentation of Tapis project. You can build a local version 
of this repository with Sphinx in a Python 3 environment (if you do not have Python
installed there are many good resources on the Internet to walk you through installation on your 
operating system). 

1. Install Sphinx using ``pip install sphinx``
2. Install the Read the Docs theme ``pip install sphinx-rtd-theme``
3. Fork the repository to your personal Github account.
4. Copy the repo from your account to your local system (using your favorite method: HTTPS, SSH, the Github CLI, or the Github Desktop app).
5. Navigate to the repo directory on your local system
6. Build the repo using ``make html`` (Mac/Linux) or ``make.bat html`` (Windows). 
7. Open the file ``[name of local repo]/build/html/index.html`` in your browser.

Note that if you replace step 1 above with ``pip install sphinx-autobuild``, you can use 
``make livehtml`` which will start a server that watches for source changes and will 
rebuild/refresh automatically. Go to http://localhost:7898/ to see its output.

Sphinx and reStructuredText
===========================

reStructuredText is the default plaintext markup language used by Sphinx, a Python documentation generator. 
rST is a bit more complex than Markdown, for example, but it includes more advanced features
like inter-page references/links and a suite of directives.

- `Sphinx's primer <http://www.sphinx-doc.org/en/stable/rest.html>`_
- `Full Docutils reference <http://docutils.sourceforge.net/rst.html>`_

  - also see its `Quick rST
    <http://docutils.sourceforge.net/docs/user/rst/quickref.html>`_ cheat sheet.

- Other projects that use rST/Sphinx:

  - `Python <https://docs.python.org/3/library/index.html>`_: click "Show Source" under "This Page" in the left sidebar.
  - `Sphinx <http://www.sphinx-doc.org/en/stable/rest.html>`_: click "Show Source" at the bottom of the right sidebar.
  - Numpy; note that the landing pages are usually coded in HTML and can be
    found in the templates directory, e.g. `Numpy's landing page
    <https://github.com/numpy/numpy/blob/master/doc/source/_templates/indexcontent.html>`_
