..
    Comment: Heirarchy of headers will now be!
    1: ### over and under
    2: === under
    3: --- under
    4: ^^^ under
    5: ~~~ under

.. _target_tapisui:

####
TapisUI
####

Introduction to TapisUI
================================

TapisUI is a React + TypeScript web application that provides a unified, user-friendly interface to the Tapis platform and its core services. TapisUI is browser-based and primarily utilizes `tapis-typescript <https://github.com/tapis-project/tapis-typescript>`_ to provide validated, up-to-date, and automated access to all Tapis Services. TapisUI is intended to be user-forward, with quick, understandable navigation and management of resources. TapisUI is designed for researchers, students, and developers who want to manage computational resources, launch jobs, deploy containers, and more from an extensible modern web interface.

.. note::
   TapisUI is highly extensible and supports a plugin/extension architecture, allowing for tenant-specific branding and new features via internal or external JavaScript modules.
   
.. figure:: /technical/images/tapisui/workflows.logs.png
   :alt: TapisUI Workflows Dashboard & Sidebar

   TapisUI Workflows dash showing workflow logs and editable workflow.

Key Features
------------

- **Unified Dashboard**: Access all major Tapis services from a single interface.
- **Modern UI**: Built with React, MUI, and TypeScript for a responsive, accessible experience.
- **Extension Architecture**: Easily add new tabs, branding, or custom workflows for your tenant or project.
- **Hot-reloading Development**: Live-edit and preview changes during extension or UI development.
- **Multi-Tenant Support**: Configure TapisUI for different tenants with custom extensions and branding.

.. figure:: /technical/images/tapisui/systems.settings.png
   :alt: TapisUI Systems Dashboard

   Tapis systems dashboard showing system details and actions.

Repository Overview
-------------------

TapisUI is a monorepo managed with `pnpm` and organized into multiple packages:

- **tapisui-common**: Shared React components and UI elements.
- **tapisui-api**: Functions for making API calls to Tapis services.
- **tapisui-hooks**: React hooks for data fetching, mutation, and error handling.
- **tapisui-extensions-core**: Core library for building and registering extensions.
- **tapisui-extension-devtools**: Developer tools for extension development.
- **example-extension**: Template for building your own extension.
- **icicle-tapisui-extension**: Example of a real extension for the ICICLE tenant.
- **scoped-tapisui-extension**: Example of a real extension for the SCOPED tenant.

See the `README.md` in the repo root for more details on the codebase and development tools.

Extension Architecture
----------------------

TapisUI supports an extension system that allows you to add new pages, tabs, and branding for specific tenants or use cases. Extensions can be developed directly in the `packages` directory or as external NPM packages. Each extension can register new sidebar tabs, provide custom React components, and configure authentication or service visibility.

`The Github repo wiki <https://github.com/tapis-project/tapis-ui/wiki/Building-an-extension-for-Tapis-UI>`_ goes over getting started developing new extensions along with guides on `how to add pages to existing extensions and examples of that. <https://github.com/tapis-project/tapis-ui/wiki/Adding-pages-via-Extensions>`_

.. note::
   Core TapisUI developers approve which extensions are rendered for which tenants. Extensions may be turned down if they conflict with existing tenant customizations. Reach out to devs when making a PR.
   Devs should be able to make changes locally and view the UI during development.




Supported Services
------------------

TapisUI provides user interfaces for the following Tapis services:

- **Systems**: Register, manage, and interact with computational and storage systems.
- **Files**: Browse, upload, download, and manage files across registered systems.
- **Apps**: Register and launch applications (workflows, scripts, containers).
- **Jobs**: Submit, monitor, and manage computational jobs.
- **Workflows**: Create, edit, and run complex workflows using a visual DAG editor.
- **Authenticator**: Manage OAuth2 clients and authentication settings.
- **Pods**: Deploy and manage long-lived containerized services (e.g., web apps, databases) in Kubernetes.

.. figure:: /technical/images/tapisui/systems.settings.png
   :alt: TapisUI Systems Dashboard

   Tapis Systems dashboard showing system details and actions.

.. figure:: /technical/images/tapisui/files.image.png
   :alt: TapisUI Files

   Tapis Files dashboard showing system details and actions.

.. figure:: /technical/images/tapisui/apps.submit.png
   :alt: TapisUI Apps Dashboard

   Tapis Apps dashboard showing system details and actions.

.. figure:: /technical/images/tapisui/Jobs.settings.png
   :alt: TapisUI Jobs Dashboard

   Tapis systems dashboard showing system details and actions.

.. figure:: /technical/images/tapisui/workflows.logs.png
   :alt: TapisUI Workflows Dashboard

   Tapis Workflows dashboard showing workflow details and actions.

.. figure:: /technical/images/tapisui/auth.create.png
   :alt: TapisUI Authenticator Dashboard

   Tapis Authenticator dashboard showing OAuth2 client details and actions.

.. figure:: /technical/images/tapisui/pods.details.png
   :alt: TapisUI Pods Dashboard

   Tapis Pods dashboard showing pod details and actions.


Getting Started with Development
================================

Developers or users looking to locally deploy TapisUI for use, for contribution, or for extension development can follow these steps. This guide assumes you have basic knowledge of JavaScript, React, and TypeScript.

1. Clone the TapisUI repository
2. Install dependencies (requires `pnpm`)
3. Build all packages
4. Start the development server which should be available at http://localhost:3000

   .. code-block:: bash

      git clone https://github.com/tapis-project/tapis-ui.git
      cd tapis-ui

      pnpm install
      pnpm -r build
      pnpm run dev


6. (Optional) Use Nix for reproducible development environments rather than installing dependencies manually. This is a declarative approach to managing dependencies and sharing instructions.
All Nix in this repo is tied to the `flake.nix` file, read the `README.md <https://github.com/tapis-project/tapis-ui>`_ for more Nix.

   .. code-block:: bash

      nix develop .#default --extra-experimental-features 'nix-command flakes'
      pnpm install
      pnpm -r build
      pnpm run dev

6. Explore the UI

   - Use the sidebar to navigate between Systems, Files, Apps, Jobs, Pods, Workflows, and more.
   - Click on any service to view, create, or manage resources.
   - Use the user menu for authentication and settings.
   - Look for help or documentation links in the sidebar or footer.

Miscellaneous / Developer Tools
------------------------------

- **pnpm**: Fast, workspace-aware package manager. See the root `README.md <https://github.com/tapis-project/tapis-ui>`_ for install instructions and common commands.
- **Nix**: Optional, but recommended for reproducible dev environments. See `flake.nix` for details.
- **Hot-reloading**: `pnpm run dev` enables live editing of extensions and UI components.
- **Changelog**: See `CHANGELOG.md <https://github.com/tapis-project/tapis-ui/blob/dev/CHANGELOG.md>`_ for recent features, bug fixes, and updates.
- **Wiki & Docs**: Visit the `TapisUI wiki <https://github.com/tapis-project/tapis-ui/wiki>`_ and `Tapis documentation <https://tapis.readthedocs.io/en/latest/contents.html>`_ for more info.

Feedback and Support
--------------------

- Create issues on the `GitHub repo <https://github.com/tapis-project/tapis-ui>`_ for bugs or feature requests.
- For tenant-specific questions, contact your tenant administrator or the Tapis team.
- For extension development help, see the example-extension and existing tenant extensions in the codebase.
- Happy exploring with TapisUI!
