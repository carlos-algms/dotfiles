# Using Gemini CLI to reduce token usage and context overflow

When analyzing large codebases, multiple files, fetching pages, doing online
searches, or reading online documentations that might exceed context limits, use
the Gemini CLI to benefit from its massive context window.

You can consider gemini as a sub-agent that can execute your requests.

MAKE sure to tell gemini to not make any code changes, just summarize or analyze
what you asked.

## Processing Online Documentation

When searching or analyzing online documentation, you can provide direct URLs or
ask Gemini to search for relevant information.

### Examples:

```bash
# Direct URL analysis:
gemini -p "Give me a deep and structured summary of this article: https://react.dev/learn/describing-the-ui. Don't make any changes"

# Find specific information:
gemini -p "In the documentation at https://react.dev/learn/describing-the-ui, how do I use props? Don't make any changes."

# Search when unsure of source:
gemini -p "Search for official React documentation on handling user events and explain key concepts. Don't make any changes."
```

## File and Directory Inclusion Syntax

When writing prompts to Gemini that needs to reference files,  
add `@` as prefix to the relative path.  
The paths should be relative to WHERE you run the gemini command:

### Examples:

```bash
# Single file analysis:
gemini -p "@src/main.py Explain this file's purpose and structure. Don't make any changes, just give a deep analysis."

# Multiple files:
gemini -p "@package.json @src/index.js Analyze the dependencies used in the code. Don't make any changes just summarize and give a list"

# Entire directory:
gemini -p "@src/ Summarize the architecture of this codebase. Don't make any changes, just give deep, and structured, overview."

# Multiple directories:
gemini -p "@src/ @tests/ Analyze test coverage for the source code. Don't make any changes, just give a detailed report."

# Current directory and subdirectories:
gemini -p "@./ Give me an overview of this entire project. Don't make any changes, just summarize the structure and the tech stack."

# Or use --all_files flag:
gemini --all_files -p "Analyze the project structure and dependencies. Don't make any changes, just summarize the architecture and tech stack."

# Implementation Verification Examples

# Check if a feature is implemented:
gemini -p "@src/ @lib/ Has dark mode been implemented in this codebase? Show me the relevant files and functions. Don't make any changes"

# Verify authentication implementation:
gemini -p "@src/ @middleware/ Is JWT authentication implemented? List all auth-related endpoints and middleware. Don't make any changes"

# Check for specific patterns:
gemini -p "@src/ Are there any React hooks that handle WebSocket connections? List them with file paths. Don't make any changes"

# Verify error handling:
gemini -p "@src/ @api/ Is proper error handling implemented for all API endpoints? Show examples of try-catch blocks. Don't make any changes"

# Verify test coverage for features:
gemini -p "@src/payment/ @tests/ Is the payment processing module fully tested? List all test cases. Don't make any changes"
```

## When to Use Gemini CLI

- Analyzing entire codebases or large directories
- Comparing multiple large files
- Need to understand project-wide patterns or architecture
- Current context window is insufficient for the task
- Working with files totaling more than 100KB
- Verifying if specific features, patterns, or security measures are implemented
- Checking for the presence of certain coding patterns across the entire
  codebase
- Reading and summarizing online documentation or articles
- Searching for information when the source is unknown
- Fetching and analyzing web pages

## Important Notes

- Paths in @ syntax are relative to your current working directory when invoking
  gemini
- The CLI will include file contents directly in the context
- No need for --yolo flag for read-only analysis
- Gemini's context window can handle entire codebases that would overflow
  Claude's context
- When checking implementations, be specific about what you're looking for to
  get accurate results
- Ask Gemini to summarize and avoid printing the full content it fetched, so it
  doesn't flood your context and token usage

====

See @~/.claude/shared.md for user's shared instructions.
