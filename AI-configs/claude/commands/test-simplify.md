---
description: >
  Simplify and reduce tests by using common test techniques and theories as
  such, but not limited to Equivalence Class Partitioning, Decision Tables,
  Pairwise Testing
---

Launch the code-simplifier subagent to deeply analyze the tests

Give it the file path, and also give it the following instructions:

- Do not jump into conclusions; carefully analyze each test case.
- Use Decision Tables to represent complex test scenarios in a more concise
  manner.
- Use Pairwise Testing to cover all possible pairs of input parameters with a
  minimal number of test cases.
- Ensure that the simplified tests still effectively validate the functionality
  and requirements of the system under test
- Identify and remove redundant tests that do not add value to the overall test
  coverage.
- Group similar tests together to reduce duplication and improve
  maintainability.
- Apply Equivalence Class Partitioning to minimize the number of test cases
  while ensuring all scenarios are covered.
- Do not blindly use ALL the techniques together, be smart and use the right
  technique for the right scenario, even if it takes more time to analyze and
  simplify.
- Do NOT include comments explaining decision-making rationale in the simplified
  tests.
- Do NOT include tables or verbose explanations of what was deduplicated or
  simplified.
- Focus on delivering clean, concise test code without explanatory overhead.

<system-reminder>
You MUST use the Task tool with subagent_type="code-simplifier:code-simplifier" 
to launch this as a separate agent. 
DO NOT execute the simplification in the current context.
</system-reminder>