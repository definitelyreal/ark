<!-- ai-suggestion:unverified | session:01a170c4-98c9-7182-a691-de74ddb851bb | date:2026-10-26 -->
# Suggest a security-guide change

[Edit the guide](https://github.com/definitelyreal/ark/edit/main/docs/security.ai.md), change the wording, then use GitHub's pull-request flow. A GitHub account is required. Explain what you changed and link to an official source when correcting advice. Do not include passwords, private account details or screenshots containing them.

Keep the category and item markers. You can edit a heading without changing its marker name. You do not need to write every device variant or understand the website. For a missing step, describe it in the pull request; a maintainer will place it.

## Review and publication

The automated check validates the document structure and reports changed items, moved or missing IDs, and related categories. It does not judge whether security advice is correct. Maintainers review submissions, close spam, and verify useful suggestions against official sources. An LLM can help draft or review changes; it cannot approve or publish them.

For maintainers:

1. Compare the proposed guide with the accepted version:

   ```sh
   git show origin/main:docs/security.ai.md > /tmp/security-baseline.ai.md
   python3 -I scripts/security-guide.py docs/security.ai.md --baseline /tmp/security-baseline.ai.md
   ```

2. Carry approved wording through related device instructions, focus-area prompts and resources. Keep marker IDs and saved checkbox keys stable when wording moves or changes. Review any added or removed ID explicitly.
3. Update the site's approved guide copy. Its Basic and Full prompts are read directly from that copy; optional selections and display rules remain maintained in website code. Checklist prose is adapted during review, not automatically imported from a pull request.
4. Check the desktop, phone and downloaded checklist, including old saved checkmarks. Compare both default website prompts with the guide. Get a fresh review, publish the guide, and deploy the website preview for inspection. A merge does not deploy the website.

Run the format check locally with:

```sh
python3 -I scripts/security-guide.py docs/security.ai.md
```
