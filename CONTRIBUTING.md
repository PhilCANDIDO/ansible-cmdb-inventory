# Contributing to ansible-cmdb

Thank you for your interest in contributing to this project! Here are guidelines to help you participate effectively.

## How to Contribute

1. **Fork** the repository
2. **Create a branch** for your modification (`git checkout -b feature/my-new-feature`)
3. **Commit your changes** (`git commit -am 'Add a new feature'`)
4. **Push to the branch** (`git push origin feature/my-new-feature`)
5. **Open a Pull Request**

## Development Guide

### Project Structure

Please respect the standard Ansible role structure:

```
ansible-cmdb/
├── defaults/         # Default role variables
├── files/            # Static files
├── handlers/         # Event handlers
├── meta/             # Role metadata
├── tasks/            # Main tasks
│   ├── hardware/     # Hardware collection tasks
│   ├── network/      # Network collection tasks
│   ├── security/     # Security collection tasks
│   ├── software/     # Software collection tasks
│   └── ...           # Other specific tasks
├── templates/        # Jinja2 templates
├── tests/            # Tests for the role
├── vars/             # Role variables
├── integration/      # CMDB integration scripts
└── examples/         # Usage examples
```

### Coding Guidelines

- **Idempotence**: Ensure all tasks are idempotent
- **Compatibility**: Tasks should work on all supported Linux distributions
- **Performance**: Optimize tasks for large server environments
- **Robustness**: Include appropriate error handling and `rescue` blocks
- **Comments**: Clearly document code, especially complex sections
- **Variables**: Use descriptive and consistent names

### Testing

Before submitting a Pull Request:

1. Test your code on different Linux distributions (Debian/Ubuntu, RHEL/CentOS, SUSE)
2. Check that the syntax is correct with `ansible-lint`
3. Ensure that the role works with and without `gather_facts`
4. Test the performance optimizations for large environments

### Documentation

Any new feature must be accompanied by:

- Updated code comments
- Updated README.md if necessary
- Usage examples in `/examples`

## Submitting Issues

Before submitting an issue:

- Check if it already exists
- Include the Ansible version and affected Linux distributions
- Provide logs and environment details

For bugs, include precise steps to reproduce the problem.

## Contact

If you have questions or suggestions, feel free to contact the main maintainer:
- [philippe.candido@cpf-informatique.fr](mailto:philippe.candido@cpf-informatique.fr)

Thank you for contributing to improving this Ansible role!