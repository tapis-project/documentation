.. code-block:: python

  from tapipy.tapis import Tapis

  # Create python Tapis client for user
  t = Tapis(base_url= "https://tacc.tapis.io",
            username="your_tacc_username",
            password="your_tacc_password")

  # Call to Tokens API to get access token
  t.get_tokens()