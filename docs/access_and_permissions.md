# Access and permissions

In addition to providing a single sign on solution for the GOV.UK publishing app suite, Signon can be used to manage users' access to apps and the permissions they have for each app. The permissions can then be used within specific non-Signon apps to dictate behaviour. This document provides a primer on key parts of how the management of access and permissions is implemented.

## Section notes

### What can you do?

Each "What can you do?" section provides a breakdown of the actions a given user (a 'granter') can take to manage access to and permissions for an app for a given user (a 'grantee').

The granter is either:

- a GOV.UK admin, meaning a user with the role "Superadmin" or "Admin"; or
- a publishing manager, meaning a user with the role "Super organisation admin" or "Organisation admin"

Each row represents an app with certain permissions set as delegatable, as indicated by the "Delegatable permissions" column. The "Grant access" column indicates whether a granter can give a grantee the `signin` permission, and the "Revoke access" column relates to removing the `signin` permission.

### Dependencies by route

Each "Dependencies by route" section provides a breakdown of which actions are determined by dependencies and a tree or trees of relevant depencencies. The aim of this section isn't to go all the way down every node of each dependency tree, but rather to provide enough context on what determines what you can do, and to make it easier to identify shared dependencies. There's a particular focus on the different policies that are hit by each route, since the policies are both fundamental to how everything works and the source of a lot of complexity.

## For the current user (self)

In this section, the granter and grantee are the same user: this is about managing your own access and permissions.

### What can you do?

#### As a GOV.UK admin

| Delegatable permissions | Grant access | Revoke access | Edit permissions | View permissions |
|-------------------------|--------------|---------------|------------------|------------------|
| None                    | ✅            | ✅             | ✅                | ✅                |
| `signin`                | ✅            | ✅             | ✅                | ✅                |
| Another permission      | ✅            | ✅             | ✅                | ✅                |

#### As a publishing manager

| Delegatable permissions | Grant access | Revoke access | Edit permissions | View permissions |
|-------------------------|--------------|---------------|------------------|------------------|
| None                    | ❌            | ❌             | ❌                | ✅                |
| `signin`                | ❌            | ✅             | ✅                | ✅                |
| Another permission      | ❌            | ❌             | ❌                | ✅                |

### Dependencies by route

#### Account applications show

These dependencies determine whether a user can:

- be redirected to the index

```mermaid
flowchart LR
    A(Account::ApplicationsController#show) --authorize [:account, Doorkeeper::Application]--> B(Account::ApplicationPolicy#show?)
```

#### Account applications index

These dependencies determine whether a user can:

- access the page
- see a link to grant access to an given app
- see a link to revoke access to an given app
- see a link to edit or view permissions for a given app

```mermaid
flowchart TD
    A(Account::ApplicationsController#index) --authorize [:account, Doorkeeper::Application]--> B(Account::ApplicationPolicy#index?)
    C(app/views/account/applications/index.html.erb) --wrap_links_in_actions_markup--> D(ApplicationTableHelper#wrap_links_in_actions_markup)
    C --account_applications_permissions_links--> E(ApplicationTableHelper#account_applications_permissions_links)
    E --policy([:account, application]).view_permissions?--> F(Account::ApplicationPolicy#view_permissions?)
    E --policy([:account, application]).edit_permissions?--> G(Account::ApplicationPolicy#edit_permissions?)
    C --account_applications_remove_access_link--> H(ApplicationTableHelper#account_applications_remove_access_link)
    H --policy([:account, application]).remove_signin_permission?--> I(Account::ApplicationPolicy#remove_signin_permission?)
    C --account_applications_grant_access_link--> J(ApplicationTableHelper#account_applications_grant_access_link)
    J --policy([:account, Doorkeeper::Application]).grant_signin_permission?--> K(Account::ApplicationPolicy#grant_signin_permission?)
```

#### Account permissions show

These dependencies determine whether a user can:

- access the page
- see a list of (all) permissions

```mermaid
flowchart TD
    A(Account::PermissionsController#show) --authorize [:account, @application], :view_permissions?--> B(Account::ApplicationPolicy#view_permissions?)
    A --@application.sorted_supported_permissions_grantable_from_ui--> C(Doorkeeper::Application#sorted_supported_permissions_grantable_from_ui)
```

#### Account permissions edit

These dependencies determine whether a user can:

- access the page
- manage (non-`signin`) permissions

```mermaid
flowchart TD
    A(Account::PermissionsController#edit) --authorize [:account, @application], :edit_permissions?--> B(Account::ApplicationPolicy#edit_permissions?)
    A --@application.sorted_supported_permissions_grantable_from_ui(include_signin: false)--> C(Doorkeeper::Application#sorted_supported_permissions_grantable_from_ui)
```

#### Account permissions update

These dependencies determine whether a user can:

- complete the controller action
- update certain permissions

```mermaid
flowchart TD
    A(Account::PermissionsController#update) --authorize [:account, @application], :edit_permissions?--> B(Account::ApplicationPolicy#edit_permissions?)
    A --UserUpdatePermissionBuilder.new( [...] ).build--> C(UserUpdatePermissionBuilder#build)
    A --UserUpdate.new(current_user, { supported_permission_ids: }, current_user, user_ip_address).call--> D(UserUpdate#call)
    D --SupportedPermissionParameterFilter.new(current_user, user, user_params) [...] .filtered_supported_permission_ids--> E(SupportedPermissionParameterFilter#filtered_supported_permission_ids)
    E --Pundit.policy_scope(current_user, SupportedPermission)--> F("SupportedPermissionPolicy (scope)")
```

## For another existing user

In this section, the granter and grantee are different users: this is about managing another user's access and permissions.

### What can you do?

#### As a GOV.UK admin

##### With access to the app

| Delegatable permissions | Grant access | Revoke access | Edit permissions | View permissions |
|-------------------------|--------------|---------------|------------------|------------------|
| None                    | ✅            | ✅             | ✅                | ✅                |
| `signin`                | ✅            | ✅             | ✅                | ✅                |
| Another permission      | ✅            | ✅             | ✅                | ✅                |
  
##### Without access to the app

| Delegatable permissions | Grant access | Revoke access | Edit permissions | View permissions |
|-------------------------|--------------|---------------|------------------|------------------|
| None                    | ✅            | ✅             | ✅                | ✅                |
| `signin`                | ✅            | ✅             | ✅                | ✅                |
| Another permission      | ✅            | ✅             | ✅                | ✅                |

#### As a publishing manager

##### With access to the app

| Delegatable permissions | Grant access | Revoke access | Edit permissions | View permissions |
|-------------------------|--------------|---------------|------------------|------------------|
| None                    | ❌            | ❌             | ❌                | ✅                |
| `signin`                | ✅            | ✅             | ✅                | ✅                |
| Another permission      | ❌            | ❌             | ❌                | ✅                |

##### Without access to the app

| Delegatable permissions | Grant access | Revoke access | Edit permissions | View permissions |
|-------------------------|--------------|---------------|------------------|------------------|
| None                    | ❌            | ❌             | ❌                | ✅                |
| `signin`                | ❌            | ❌             | ❌                | ✅                |
| Another permission      | ❌            | ❌             | ❌                | ✅                |

### Dependencies by route

#### Users applications show

These dependencies determine whether a user can:

- be redirected to the index

```mermaid
flowchart LR
    A(Users::ApplicationsController#show) --authorize user, :edit?--> B(UserPolicy#edit?)
```

#### Users applications index

These dependencies determine whether a user can:

- access the page
- see a link to grant access to an given app
- see a link to revoke access to an given app
- see a link to edit or view permissions for a given app

```mermaid
flowchart TD
    A(Users::ApplicationsController#index) --authorize @user, :edit?--> B(UserPolicy#edit?)
    C(app/views/users/applications/index.html.erb) --wrap_links_in_actions_markup--> D(ApplicationTableHelper#wrap_links_in_actions_markup)
    C --users_applications_permissions_links--> E(ApplicationTableHelper#users_applications_permissions_links)
    E --Users::ApplicationPolicy.new(current_user, { application:, user: }).view_permissions?--> F(Users::ApplicationPolicy#view_permissions?)
    F --Pundit.policy(current_user, user).edit?--> G(UserPolicy#edit?)
    E --Users::ApplicationPolicy.new(current_user, { application:, user: }).edit_permissions?--> H(Users::ApplicationPolicy#edit_permissions?)
    H --Pundit.policy(current_user, user).edit?--> G
    C --users_applications_remove_access_link--> I(ApplicationTableHelper#users_applications_remove_access_link)
    I --Users::ApplicationPolicy.new(current_user, { application:, user: }).remove_signin_permission?--> J(Users::ApplicationPolicy#remove_signin_permission?)
    J --Pundit.policy(current_user, user).edit?--> G
    C --users_applications_grant_access_link--> K(ApplicationTableHelper#users_applications_grant_access_link)
    K --Users::ApplicationPolicy.new(current_user, { application:, user: }).grant_signin_permission?--> L(Users::ApplicationPolicy#grant_signin_permission?)
    L --Pundit.policy(current_user, user).edit?--> G
```

#### Users permissions show

These dependencies determine whether a user can:

- access the page
- see a list of (all) permissions

```mermaid
flowchart TD
    A(Users::PermissionsController#show) --authorize @user, :edit?--> B(UserPolicy#edit?)
    A --@application.sorted_supported_permissions_grantable_from_ui--> C(Doorkeeper::Application#sorted_supported_permissions_grantable_from_ui)
```

#### Users permissions edit

These dependencies determine whether a user can:

- access the page
- manage (non-`signin`) permissions

```mermaid
flowchart TD
    A(Users::PermissionsController#edit) --authorize [{ application: @application, user: @user }], :edit_permissions?, policy_class: Users::ApplicationPolicy--> B(Users::ApplicationPolicy#edit_permissions?)
    B --Pundit.policy(current_user, user).edit?--> C(UserPolicy#edit?)
    A --@application.sorted_supported_permissions_grantable_from_ui(include_signin: false)--> D(Doorkeeper::Application#sorted_supported_permissions_grantable_from_ui)
```

#### Users permissions update

These dependencies determine whether a user can:

- complete the controller action
- update certain permissions

```mermaid
flowchart TD
    A(Users::PermissionsController#update) --authorize [{ application: @application, user: @user }], :edit_permissions?, policy_class: Users::ApplicationPolicy--> B(Users::ApplicationPolicy#edit_permissions?)
    B --Pundit.policy(current_user, user).edit?--> C(UserPolicy#edit?)
    A --UserUpdatePermissionBuilder.new( [...] ).build--> D(UserUpdatePermissionBuilder#build)
    A --UserUpdate.new(@user, { supported_permission_ids: }, current_user, user_ip_address).call--> E(UserUpdate#call)
    E --SupportedPermissionParameterFilter.new(current_user, user, user_params) [...] .filtered_supported_permission_ids--> F(SupportedPermissionParameterFilter#filtered_supported_permission_ids)
    F --Pundit.policy_scope(current_user, SupportedPermission)--> G("SupportedPermissionPolicy (scope)")
```

## For a new user

### What can you do?

The following actions are taken in the process of inviting a new user - once the invitation is sent, refer to the [For another existing user](#for-another-existing-user) section.

#### As a GOV.UK admin

| Send invitation | Grant access | Edit permissions |
|-----------------|--------------|------------------|
| ✅               | ✅            | ✅                |

#### As a publishing manager

| Send invitation | Grant access | Edit permissions |
|-----------------|--------------|------------------|
| ❌               | ❌            | ❌                |

### Dependencies by route

#### Invitations new

These dependencies determine whether a user can:

- access the page
- see certain apps to which to grant the new user access
- see certain permissions for those apps to grant the new user

```mermaid
flowchart TD
    A(InvitationsController#new) --authorize User--> B(UserPolicy#new?)
    C(app/views/devise/invitations/new.html.erb) --"options_for_permission_option_select(application:, user: f.object)"--> D(UsersHelper#options_for_permission_option_select)
    D --application.sorted_supported_permissions_grantable_from_ui--> E(Doorkeeper::Application#sorted_supported_permissions_grantable_from_ui)
```

#### Invitations create

These dependencies determine whether a user can:

- complete the controller action

```mermaid
flowchart TD
    A(InvitationsController#create) --authorize User--> B(UserPolicy#create?)
```

## Important files

### Models

| Class                                                                    | Relevant associations                                                                       |
|--------------------------------------------------------------------------|---------------------------------------------------------------------------------------------|
| [Doorkeeper::Application](/app/models/doorkeeper/application.rb)         | Has many supported permissions                                                              |
| [SupportedPermission](/app/models/supported_permission.rb)               | Belongs to an app                                                                           |
| [UserApplicationPermission](/app/models//user_application_permission.rb) | Joins users with supported permissions (and apps), determining what individual users can do |

### Controllers

| Class                                                                                  | Responsibility                                                                     |
|----------------------------------------------------------------------------------------|------------------------------------------------------------------------------------|
| [Account::ApplicationsController](/app/controllers/account/applications_controller.rb) | Managing own access to apps and accessing own permissions routes                   |
| [Account::PermissionsController](/app/controllers/account/permissions_controller.rb)   | Managing own permissions                                                           |
| [InvitationsController](/app/controllers/invitations_controller.rb)                    | Giving users access to apps and permissions while creating their account           |
| [Users::ApplicationsController](/app/controllers/users/applications_controller.rb)     | Managing other users' access to apps and accessing other users' permissions routes |
| [Users::PermissionsController](/app/controllers/users/permissions_controller.rb)       | Managing other users' permissions                                                  |

### Policies

| Class                                                                                                       | Responsibility                                                                                                                                                            |
|-------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| [Account::ApplicationPolicy](/app/policies/account/application_policy.rb)                                   | Determining whether granters can see and update their own access and permissions                                                                                          |
| [SupportedPermissionPolicy](/app/policies/supported_permission_policy.rb)                                   | Determining which permissions can be updated by a given granter                                                                                                           |
| [UserPolicy](/app/policies/user_policy.rb)                                                                  | Determining whether a granter can update a grantee's access and permissions*, and whether they can invite a new user and grant them access and permissions in the process |
| [UserApplicationPermissionPolicy](/app/policies/user_application_permission_policy.rb)                      | Determining whether a granter can update a grantee's access and permissions*                                                                                              |

\* the responsibility of these two policies is hard to distinguish in this context, but as seen in the dependency trees for existing users, the `UserApplicationPermissionPolicy` depends on the `UserPolicy`, and in reality the latter is larger in scope. The `InvitationsController` depends on different parts of the `UserPolicy`, for instance.

### Others

| Class                                                                               | Responsibility                                                                                 |
|-------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| [ApplicationTableHelper](/app/helpers/application_table_helper.rb)                  | Generating links to view/manage access and permissions dependent on policy-based authorisation |
| [SupportedPermissionParameterFilter](/lib/supported_permission_parameter_filter.rb) | Ensuring granters can only change permissions they're authorised to manage                     |
| [UserUpdate](/app/services/user_update.rb)                                          | Updating a user's permissions                                                                  |
| [UserUpdatePermissionBuilder](/app/models/user_update_permission_builder.rb)        | Generating a list of updated permissions                                                       |
| [UsersHelper](/app/helpers/users_helper.rb)                                         | Generating a list of permissions that can be granted when creating a new user                  |
