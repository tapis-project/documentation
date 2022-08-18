-------------------------
Directives (experimental)
-------------------------

Directives are a special set of commands that override the default execution behavior of a pipeline
or its tasks. Directives can be provided in either a commit message or the request body.

Commit Message Directives
~~~~~~~~~~~~~~~~~~~~~~~~~

Directives must be placed inside square brackets at the end of the commit message
Multiple Directives must be separated by a pipe "|"
Directives that require a key-value pair must have the key and value separated by a colon ":"
The directive string in a commit message must comply with the following regex(Python flavor) pattern: 
``\[[a-zA-Z0-9\s:|._-]+\]``

**Directive Usage Examples**

.. code-block:: bash

  git commit -m "Some commit message [no_push]"

.. code-block:: bash
  
  git commit -m "Some commit message [cache|custom_tag:my-custom-tagV.1]"

**List of Directives**

  * ``custom_tag`` - Overrides the destination ``image_tag`` on an *image_build* task. Tags an image with the value provided after "custom_tag:".
  * ``commit_destination`` - Overrides the destination ``image_tag`` on an *image_build* task. Dynamically tags the image with the short commit sha of the last commit(and push) that triggered the pipeline.
  * ``no_push`` (pending) - Overrides the image build destination. Creates a local file
  * ``dry_run`` - prevents the pipeline from running. Used to test whether the desired Pipeline is matched.
  * ``nocache`` (unsupported) - prevents the image builder in an "image_build" task from caching the image layers. This will result in longer build times for subsequent builds.