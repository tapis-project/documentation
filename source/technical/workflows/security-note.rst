.. note:: 

  **Security Note**

  In order to create and run workflows that are automated and reproducible, the Workflow Executor must 
  sometimes be furnished with secrets(passwords, access keys, access secrets, ssh keys, etc) that enable it access restricted resources.

  To ensure the safe storage and retrieval of this sensitive data, the Workflows service integrates with *Tapis SK*, a built-in secrets management
  service backed by *Hashicorp Vault*.

  It is also important to note that, when a user creates a task that accesses some restricted resource,
  the Workflow Executor will execute that task on behalf of that user with the credentials that they provided
  for every run of the pipeline. If those credentials expire, or the user has their access revoked for those
  resources, the pipeline run will fail on that task.