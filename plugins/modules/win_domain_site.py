#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2022 VMware, Inc. All Rights Reserved.
# SPDX-License-Identifier: Internal

ANSIBLE_METADATA = {'metadata_version': '1.1',
                    'status': ['preview'],
                    'supported_by': 'community'}

DOCUMENTATION = r'''
---
module: win_domain_site
short_description: Manages Active Directory Sites
description:
- Used to add, remove or rename Sites in Active Directory
options:
  name:
    description:
    - The name of the site
    required: True
    type: str
  state:
    description:
    - When C(state=absent), will remove the site if it exists.
    - When C(state=present), will create a site.
    - When C(state=rename), will rename site to the value defined in new_site.
    choices:
    - absent
    - present
    - rename
    default: present
    type: str
  new_name:
    description:
    - When C(state=rename), defines the new site name.
    required: False
    type: str
author:
- Chris Gallagher (@git-cgallagher)
'''

EXAMPLES = r'''
- name: create DC01 site
  win_domain_site:
    name: DC01
    state: present

- name: delete DC01 site
  win_domain_site:
    name: DC01
    state: absent

- name: rename existing ad site Default-First-Site-Link
  win_domain_site:
    name: Default-First-Site-Link
    state: rename
    new_name: DC01
'''

RETURN = r'''
#
'''