"""
DeepSeek Model Selection Guide for Dayyakattai project.

Available Models (as of 2026):
  deepseek-chat      = DeepSeek-V3   : 64k ctx, fastest, best for quick patches & simple generation
  deepseek-reasoner  = DeepSeek-R1   : 64k ctx, slower, best for complex logic, full-file rewrites,
                                        architecture decisions, test generation, and multi-step reasoning

Model Selection Strategy:
  USE deepseek-reasoner (R1) for:
    - Full-file rewrites (large files > 400 lines)
    - Complex game logic (rules, state machines, edge cases)
    - Architecture decisions (data models, API design)
    - Test generation & logic verification
    - Any prompt where reasoning quality matters more than speed

  USE deepseek-chat (V3) for:
    - Quick single-method patches
    - Simple UI widget generation
    - Regex/text transforms
    - Documentation generation
    - Fast iteration when context is small (< 2000 tokens)

Context Window Tips:
  - Both models have 64k token context (~48k chars usable)
  - For files > 500 lines, send only the RELEVANT sections + class signatures
  - Use chunk-based patching (multi_replace) rather than full-file rewrites
  - For the board file (1000+ lines): extract only the target method + its dependencies

Cost Reference (approximate):
  deepseek-chat:     $0.14/M input tokens,  $0.28/M output tokens
  deepseek-reasoner: $0.55/M input tokens,  $2.19/M output tokens (includes reasoning tokens)

Helper function (use in all scripts):
"""

def select_model(task_type: str) -> str:
    """
    Select the best DeepSeek model for a task.

    task_type options:
      'patch'       - Small targeted code change     -> V3 (fast)
      'full_file'   - Full file rewrite              -> R1 (quality)
      'logic'       - Complex business logic         -> R1 (reasoning)
      'ui'          - UI/widget generation           -> V3 (fast)
      'test'        - Test generation & QA           -> R1 (reasoning)
      'transform'   - Text transform, regex fix      -> V3 (fast)
      'architecture'- Design decisions               -> R1 (reasoning)
    """
    R1_TASKS = {'full_file', 'logic', 'test', 'architecture'}
    model = 'deepseek-reasoner' if task_type in R1_TASKS else 'deepseek-chat'
    print(f"  [model] {task_type} -> {model}")
    return model
