# Contributing

Thank you for your interest in contributing to this project!

## How to Contribute

1. **Fork** the repository.
2. **Create a feature branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Format and validate** your Terraform code:
   ```bash
   terraform fmt -recursive
   terraform validate
   ```
4. **Commit** your changes with a clear, descriptive commit message.
5. **Push** your branch and open a **Pull Request** against `main`.

## Guidelines

- Ensure all Terraform files pass `terraform fmt` and `terraform validate` before submitting.
- Keep pull requests focused on a single change.
- Update documentation if your change affects module inputs, outputs, or behavior.
- Follow existing code style and conventions.

## Reporting Issues

If you find a bug or have a feature request, please open an issue with a clear description and, if applicable, steps to reproduce.
