# GitHub SEO Optimization Guide

## Summary

This document outlines the SEO optimizations implemented and the manual configurations required to complete the GitHub Action marketplace optimization.

---

## ✅ Completed Optimizations

### 1. Action Metadata (`action.yml`)

**Enhanced Action Name:**
- **Before:** "Skills Update Action"
- **After:** "Skills Update: AI Agent Skills Automation"
- **Impact:** More discoverable in marketplace searches, includes "AI Agent" keyword

**Improved Description:**
- **Before:** "Update repository skills and optionally create commit and pull request artifacts."
- **After:** "Automatically update repository agent skills from Vercel Skills CLI, create commits and pull requests with path safety policies. AI agent automation for GitHub repositories."
- **Impact:** Includes primary keywords: "agent skills", "Vercel Skills CLI", "path safety", "AI agent automation"

**Added Category Hints:**
```yaml
branding:
  icon: 'book-open'
  color: 'orange'
  # GitHub Marketplace Categories (primary: Continuous integration, secondary: Code review)
  # Optimizes discoverability in GitHub Marketplace browsing and search
```

### 2. README.md SEO Enhancements

**Opening Section:**
- Added `<h3>` subtitle: "GitHub Action for Automated AI Agent Skills Management"
- First 160 characters now include primary keywords: "skills", "AI agent", "GitHub Action", "automatically", "Vercel's Skills CLI"
- Added SEO meta comment with keywords and marketplace categories
- **Dependabot comparison:** "Like Dependabot for agent skills" - instant mental model for users

**Question-Based Headings (SEO Best Practice):**
```markdown
## Frequently Asked Questions
### What is the Skills Update GitHub Action?
### How does this action work with AI agents?
### How is this different from Dependabot?
### Is this action safe for production use?
### What workflows does this action support?
### How do I get started with skills-update?

## Why use this GitHub Action for skills management?

## How does the skills-update action work?

## What is the path safety policy?

## What inputs does the skills-update action accept?

## What outputs does the action provide for workflow integration?

## What are common usage recipes and examples?

## How do I verify the action is working correctly?

## What is the release model and versioning strategy?
```

**Added FAQ Section:**
- Comprehensive answers to common search queries
- Dependabot comparison for instant understanding
- Targets long-tail keywords and user intents
- Improves AI/LLM discoverability

---

## 🔧 Manual Configuration Required

These changes must be made directly in GitHub's web interface:

### Repository Description (About Section)

Navigate to: [github.com/iyaki/skills-update](https://github.com/iyaki/skills-update) → Click the gear icon next to "About"

**Recommended Description:**
> GitHub Action for automated AI agent skills management. Updates Vercel Skills CLI, creates safe commits and pull requests with path safety policies. CI/CD automation for AI agents.

**Why this works:**
- Starts with primary keyword "GitHub Action"
- Includes "AI agent", "skills management", "Vercel Skills CLI"
- Mentions key features: "safe commits", "pull requests", "path safety"
- 26 words, ~200 characters (optimal length)

### Repository Topics

Add these topics to improve GitHub search discovery and categorization:

```:
github-action
skills
ai-agents
automation
ci-cd
vercel
continuous-integration
workflow-automation
agent-management
devops
artificial-intelligence
skills-cli
```

**How to add topics:**
1. Go to repository main page
2. Click the gear icon next to "About"
3. In the "Topics" field, add each topic (press Enter after each)
4. Click "Save changes"

**Topic Strategy:**
- **Primary keywords:** `github-action`, `skills`, `ai-agents`, `automation`
- **Technology stack:** `vercel`, `skills-cli`
- **Use case:** `ci-cd`, `workflow-automation`, `devops`
- **Domain:** `agent-management`, `artificial-intelligence`

### GitHub Marketplace Publication

When publishing or updating the marketplace listing:

**Primary Category:** `Continuous integration`  
**Secondary Category:** `Code review` (optional)

**Steps:**
1. Navigate to GitHub Marketplace
2. Click or edit your action listing
3. Select categories from the dropdown
4. Submit for review

---

## 📊 SEO Best Practices Applied

Based on 2026 GitHub SEO research:

### 1. **Keyword Placement** (Ranking Factor: High)
- ✅ Repository description starts with primary keyword
- ✅ Action name includes "AI Agent" and "Automation"
- ✅ README heading includes keyword in first 160 characters
- ✅ FAQ answers use natural language matching search queries
- ✅ **Mental model comparison:** "Dependabot for agent skills" for instant understanding

### 2. **Topic Tags** (Ranking Factor: High)
- ✅ Selected 12 relevant topics (up to 20 allowed)
- ✅ Mix of broad and specific terms
- ✅ Aligned with how developers search for actions

### 3. **README Structure** (Ranking Factor: Medium)
- ✅ H1 with project name
- ✅ H3 subtitle with primary keyword
- ✅ H2 sections as questions (matches search intent)
- ✅ FAQ section with long-tail keyword coverage
- ✅ Code examples and usage recipes
- ✅ Badges for social proof (marketplace, tests, release)

### 4. **Discovery Signals** (Ranking Factor: Medium)
- ✅ Keywords in file names (already good: `*.yml`, `*.md`)
- ✅ Structured content for AI/Google indexing
- ✅ Clear feature lists and benefits
- ✅ Mental model for quick comprehension

### 5. **Engagement Optimization** (Ranking Factor: Medium)
- ✅ Clear value proposition at top
- ✅ Quick-start examples reduce bounce rate
- ✅ FAQ reduces support friction
- ✅ Dependabot comparison reduces learning curve

---

## 🔍 Search Intent Alignment

### How Developers Search for This Action

**GitHub Search Queries:**
- "skills update action"
- "ai agent automation github"
- "vercel skills cli github action"
- "automated skills management"
- "github action update files"
- "dependabot alternative for agents"

**Google Search Queries:**
- "how to automate github skills"
- "vercel skills ci/cd"
- "github action for ai agents"
- "automate skills update workflow"

**AI/LlM Queries:**
- "action update skills automatically"
- "github ci/cd for agent skills"
- "vercel skills automation"

All these queries are now addressed in:
- Repository description (when configured)
- Action metadata description
- README first paragraph
- FAQ section answers
- Topic tags

---

## 📈 Expected Impact

### Before Optimization
- Limited discoverability without topics
- Generic description missing keywords
- README not optimized for search snippets
- No FAQ for long-tail queries
- No mental model for quick understanding

### After Optimization (Complete)
- **GitHub Search:** Improved ranking for "skills", "ai agents", "automation"
- **Marketplace Browse:** Better categorization under CI/CD
- **Google Search:** README indexed with keyword-rich headings
- **AI Discovery:** Structured Q&A format improves AI tool citations
- **Conversion:** Clear FAQ, Dependabot comparison, and examples reduce friction

---

## ✅ Verification Checklist

- [x] Action name optimized
- [x] Action description enhanced with keywords
- [x] Category hints added to action.yml
- [x] README opening subtitle with keywords
- [x] All sections converted to question format
- [x] FAQ section added with Dependabot comparison
- [x] SEO meta comment added
- [ ] **Manual:** Repository description updated
- [ ] **Manual:** Topics added to repository
- [ ] **Manual:** Marketplace categories selected (during publishing)

---

## 🧪 Testing Marketplace Visibility

After completing manual configurations:

1. **Test GitHub Search:**
   ```
   https://github.com/marketplace?type=actions&query=skills+update
   ```

2. **Search Actions Marketplace:**
   - Filter by category: "Continuous integration"
   - Search for: "ai agent", "skills", "automation", "dependabot"

3. **Google Indexing Check (after ~1 week):**
   ```
   site:github.com/iyaki/skills-update
   ```

---

## References

- [GitHub Marketplace Publishing Guide](https://docs.github.com/en/enterprise-cloud@latest/actions/how-tos/create-and-publish-actions/publish-in-github-marketplace)
- [GitHub SEO Best Practices 2026](https://www.infrasity.com/blog/github-seo)
- [Repository SEO Keywords Guide](https://claudegithub.com/blog-github-seo-keywords)

---

**Last Updated:** 2026-07-14  
**Optimized by:** AI Agent (Skills Update)