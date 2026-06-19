/// Simulates the JSON payload a server would return for the SDUI sales page.
/// The Flutter app fetches this and renders it dynamically.
const String sduiPageData = '''
{
  "schema_version": "1.0",
  "page_title": "Server-Driven UI for Flutter",
  "sections": [
    {
      "type": "hero",
      "props": {
        "badge": "Flutter + Server-Driven UI",
        "badgeIcon": "bolt",
        "headline": "Dynamic Flutter UI\\nPowered by Your Server",
        "subtitle": "Stop rebuilding your app for every UI change. Ship updates in real time, personalize at scale, and eliminate app store bottlenecks with a server-driven architecture built for Flutter.",
        "chips": ["No App Store Delays", "Real-Time Updates", "Cross-Platform", "A/B Testing", "Personalized UX"],
        "cta": "Start Building"
      }
    },
    {
      "type": "comparisonTable",
      "props": {
        "title": "Traditional vs SDUI",
        "subtitle": "See the difference side by side"
      },
      "children": [
        {"type": "comparisonRow", "props": {"label": "UI Changes", "traditional": "Full app rebuild + store approval", "sdui": "Instant server update"}},
        {"type": "comparisonRow", "props": {"label": "Release Cycle", "traditional": "Days to weeks", "sdui": "Minutes to hours"}},
        {"type": "comparisonRow", "props": {"label": "Personalization", "traditional": "Static per build", "sdui": "Dynamic per segment"}},
        {"type": "comparisonRow", "props": {"label": "A/B Testing", "traditional": "Requires engineering sprint", "sdui": "Server-side toggle"}},
        {"type": "comparisonRow", "props": {"label": "Platform Coverage", "traditional": "Per-platform builds", "sdui": "Single schema, all platforms"}},
        {"type": "comparisonRow", "props": {"label": "Business Control", "traditional": "Engineering bottleneck", "sdui": "Team-driven changes"}},
        {"type": "comparisonRow", "props": {"label": "Cost per Change", "traditional": "High (build + test + deploy)", "sdui": "Low (schema edit only)"}},
        {"type": "comparisonRow", "props": {"label": "Offline Support", "traditional": "N/A", "sdui": "Cached schemas"}}
      ]
    },
    {
      "type": "sectionHeader",
      "props": {
        "title": "What is SDUI?",
        "subtitle": "UI as a Server-Managed Capability",
        "body": "Server-Driven UI is a design approach where the structure and content of your app interface is dictated by the server instead of being hardcoded. The app fetches instructions (JSON) from the backend and renders the UI dynamically at runtime."
      }
    },
    {
      "type": "infoCard",
      "props": {"icon": "code", "title": "Define on Server", "description": "Your backend sends JSON schemas describing every UI element, its properties, and its hierarchy."}
    },
    {
      "type": "infoCard",
      "props": {"icon": "device_mobile", "title": "Render on Client", "description": "Flutter widget engine maps schema definitions to native widgets in real time with zero performance penalty."}
    },
    {
      "type": "infoCard",
      "props": {"icon": "refresh", "title": "Update Instantly", "description": "Change the schema on your server. Every user sees the new UI immediately. No app store review, no rebuild."}
    },
    {
      "type": "sectionHeader",
      "props": {
        "title": "How It Works",
        "subtitle": "From schema to screen in 4 steps"
      }
    },
    {
      "type": "step",
      "props": {"step": "01", "title": "Define the UI Schema", "description": "Your server sends structured JSON describing components, their properties, and hierarchy. Each element has a type, props, children, and actions."}
    },
    {
      "type": "step",
      "props": {"step": "02", "title": "Map Schema to Widgets", "description": "Flutter widget registry matches each schema type to a corresponding widget class. A button maps to ElevatedButton, text to Text widget, etc."}
    },
    {
      "type": "step",
      "props": {"step": "03", "title": "Render Dynamically", "description": "Flutter constructs the widget tree in real time from the interpreted schema. The result is fluid, native-quality UI at runtime."}
    },
    {
      "type": "step",
      "props": {"step": "04", "title": "Iterate Without Limits", "description": "Update the schema on your server anytime. Push new banners, reorder sections, A/B test variations all without a single app store submission."}
    },
    {
      "type": "sectionHeader",
      "props": {
        "title": "Live Schema Example",
        "subtitle": "This JSON defines an entire screen",
        "body": "The server sends structured JSON. Flutter interprets it and renders the UI. Change the JSON, change the UI — instantly."
      }
    },
    {
      "type": "codeBlock",
      "props": {
        "code": "{\\n  \\"schema_version\\": \\"1.0\\",\\n  \\"type\\": \\"container\\",\\n  \\"props\\": {\\n    \\"padding\\": 16,\\n    \\"bgColor\\": \\"surface\\"\\n  },\\n  \\"children\\": [\\n    {\\n      \\"type\\": \\"text\\",\\n      \\"props\\": {\\n        \\"content\\": \\"Welcome!\\",\\n        \\"style\\": \\"heading\\"\\n      }\\n    },\\n    {\\n      \\"type\\": \\"button\\",\\n      \\"props\\": {\\n        \\"text\\": \\"Get Started\\",\\n        \\"variant\\": \\"primary\\",\\n        \\"action\\": \\"navigate\\",\\n        \\"route\\": \\"/onboarding\\"\\n      }\\n    },\\n    {\\n      \\"type\\": \\"image\\",\\n      \\"props\\": {\\n        \\"src\\": \\"https://cdn.example.com/hero.png\\",\\n        \\"width\\": \\"fill\\"\\n      }\\n    }\\n  ]\\n}",
        "caption": "Renders: Container → Text(\\"Welcome!\\") + Button + Image"
      }
    },
    {
      "type": "sectionHeader",
      "props": {
        "title": "Why Flutter?",
        "subtitle": "The perfect engine for SDUI"
      }
    },
    {
      "type": "miniCard",
      "props": {"icon": "layout_grid", "title": "Widget Tree Flexibility", "description": "Everything in Flutter is a widget — from layout to gestures. Mapping schema nodes to renderable elements is completely natural."}
    },
    {
      "type": "miniCard",
      "props": {"icon": "devices", "title": "True Cross-Platform", "description": "One Flutter codebase, one schema, every platform. Deploy UI updates simultaneously to Android, iOS, web, and desktop."}
    },
    {
      "type": "miniCard",
      "props": {"icon": "bolt", "title": "High-Performance Rendering", "description": "Flutter handles dynamic widget trees just as efficiently as static ones. Users experience no difference in performance."}
    },
    {
      "type": "miniCard",
      "props": {"icon": "layers_difference", "title": "Single Codebase, Infinite Layouts", "description": "Build the rendering engine once. The server handles every layout variation. No more hardcoding screen after screen."}
    },
    {
      "type": "sectionHeader",
      "props": {
        "title": "Benefits",
        "subtitle": "Why businesses choose SDUI + Flutter"
      }
    },
    {
      "type": "benefitGrid",
      "props": {},
      "children": [
        {"type": "benefitCard", "props": {"icon": "bolt", "title": "Faster Iteration", "description": "Ship UI changes instantly from the server. No app store approvals, no release cycles."}},
        {"type": "benefitCard", "props": {"icon": "users", "title": "Personalization at Scale", "description": "Different layouts by segment, location, or behavior. Every user sees what converts best."}},
        {"type": "benefitCard", "props": {"icon": "coin", "title": "Lower Engineering Costs", "description": "One rendering engine serves all use cases. No rebuilding layouts for every campaign."}},
        {"type": "benefitCard", "props": {"icon": "flask", "title": "Accelerated Experimentation", "description": "Run A/B tests from the server. Measure, learn, and optimize without engineering sprints."}},
        {"type": "benefitCard", "props": {"icon": "shield_check", "title": "Business-Engineering Alignment", "description": "Product teams initiate changes directly. Engineering focuses on the rendering engine."}},
        {"type": "benefitCard", "props": {"icon": "globe", "title": "Cross-Platform Consistency", "description": "Single schema updates Android, iOS, Web, Desktop simultaneously."}}
      ]
    },
    {
      "type": "sectionHeader",
      "props": {
        "title": "Architecture",
        "subtitle": "Three layers, infinite possibilities"
      }
    },
    {
      "type": "architectureLayer",
      "props": {
        "icon": "server_2",
        "layer": "Server Layer",
        "tag": "Source of Truth",
        "items": ["Stores and delivers UI schemas", "Business teams configure changes", "Governance, audit logging & versioning", "Segment targeting (AB, geo, device)"]
      }
    },
    {
      "type": "architectureLayer",
      "props": {
        "icon": "file_code",
        "layer": "Schema Layer",
        "tag": "Blueprint of UI",
        "items": ["JSON definitions of every component", "Versioned for backward compatibility", "Defines layout, style, actions & data", "Enables A/B experiments & rollbacks"]
      }
    },
    {
      "type": "architectureLayer",
      "props": {
        "icon": "device_mobile",
        "layer": "Flutter Client",
        "tag": "Rendering Engine",
        "items": ["Maps schema nodes to Flutter widgets", "Handles interactions, navigation & state", "Caching for offline & low-connectivity", "Graceful fallbacks on errors"]
      }
    },
    {
      "type": "sectionHeader",
      "props": {
        "title": "Supporting Infrastructure",
        "subtitle": "The backbone of production SDUI"
      }
    },
    {
      "type": "miniCard",
      "props": {"icon": "api", "title": "API Delivery", "description": "Schemas delivered via CDN with etags and last-modified headers for efficient refresh. Real-time updates with segment targeting."}
    },
    {
      "type": "miniCard",
      "props": {"icon": "database", "title": "Smart Caching", "description": "Last-good schema cached on device. Critical screens render offline. Intelligent expiry for connectivity-aware UI."}
    },
    {
      "type": "miniCard",
      "props": {"icon": "shield", "title": "Kill Switches", "description": "Server-driven kill switch reverts broken layouts to safe defaults instantly. Non-negotiable for production SDUI."}
    },
    {
      "type": "miniCard",
      "props": {"icon": "eye", "title": "Observability", "description": "Render time, widget count, error rates, and user events logged for every dynamic screen."}
    },
    {
      "type": "sectionHeader",
      "props": {
        "title": "Implementation Roadmap",
        "subtitle": "9 steps from planning to production"
      }
    },
    {"type": "stepCompact", "props": {"num": 1, "title": "Define UI Schema", "description": "Start with 6-10 atomic components. Document in a shared spec that Product, Design, and Engineering all read."}},
    {"type": "stepCompact", "props": {"num": 2, "title": "Build Widget Registry", "description": "Create a widget factory mapping schema nodes to Flutter widgets. Keep rendering pure with no API calls inside factories."}},
    {"type": "stepCompact", "props": {"num": 3, "title": "Handle Layouts", "description": "Represent Row, Column, Stack, Grid as schema nodes. Enforce depth limits and overflow handling."}},
    {"type": "stepCompact", "props": {"num": 4, "title": "Declarative Actions", "description": "Represent taps, submits, navigation as schema actions. Use Navigator 2.0 for deep-link support."}},
    {"type": "stepCompact", "props": {"num": 5, "title": "Version & Compat", "description": "Add schema_version at root. Build compatibility layer for old clients to fall back gracefully."}},
    {"type": "stepCompact", "props": {"num": 6, "title": "CDN + Cache", "description": "Host schemas behind CDN with etags. Cache on-device. Support AB, geo, device targeting via query params."}},
    {"type": "stepCompact", "props": {"num": 7, "title": "Observability", "description": "Log render time, widget count, errors. Add kill switch for instant revert of broken layouts."}},
    {"type": "stepCompact", "props": {"num": 8, "title": "Test Strategy", "description": "Unit test registry mappings. Contract test server output. Golden tests for visual regressions. CI linting for schemas."}},
    {"type": "stepCompact", "props": {"num": 9, "title": "Governance", "description": "Treat SDUI as its own product with roadmap, owners, SLAs. Publish playbooks for PMs and designers."}},
    {
      "type": "sectionHeader",
      "props": {
        "title": "Use Cases",
        "subtitle": "SDUI across industries"
      }
    },
    {
      "type": "useCase",
      "props": {"icon": "shopping_cart", "industry": "E-Commerce", "description": "Promotional banners, product page reconfiguration, cross-sell by segment without shipping builds.", "impact": "Higher conversion, faster A/B cycles"}
    },
    {
      "type": "useCase",
      "props": {"icon": "building_bank", "industry": "Fintech", "description": "Role-aware dashboards for investors, borrowers, or merchants. Compliance notices deploy instantly when regulations change.", "impact": "Faster regulatory response, tailored engagement"}
    },
    {
      "type": "useCase",
      "props": {"icon": "backpack", "industry": "SaaS & Productivity", "description": "Dynamic onboarding sequencing, paywall A/B testing, pricing tile experiments. No engineering cycles needed.", "impact": "Increased trial-to-paid conversion, reduced CAC"}
    },
    {
      "type": "useCase",
      "props": {"icon": "news", "industry": "Media & Content", "description": "Curated homefeeds per locale, hero layout changes during events, tokenized editorial styles across regions.", "impact": "Relevance at scale, stronger session depth"}
    },
    {
      "type": "useCase",
      "props": {"icon": "plane", "industry": "Travel & Mobility", "description": "Contextual trip modules, surge communication panels, dynamic safety prompts during peak demand.", "impact": "Lower support escalations, higher NPS"}
    },
    {
      "type": "useCase",
      "props": {"icon": "heart", "industry": "Healthcare", "description": "Symptom checker updates, consent form changes, region-specific care pathways. Instant clinical guidance updates.", "impact": "Compliance confidence, safer patient interactions"}
    },
    {
      "type": "useCase",
      "props": {"icon": "briefcase", "industry": "Enterprise", "description": "Role-based task lists, audit checklists, emergency protocol pushes. Centralized policy changes for distributed teams.", "impact": "Operational consistency, rapid policy response"}
    },
    {
      "type": "sectionHeader",
      "props": {
        "title": "Testimonials",
        "subtitle": "What industry leaders say"
      }
    },
    {
      "type": "testimonial",
      "props": {"quote": "SDUI cut our feature release time from 2 weeks to 2 hours. Our marketing team now pushes campaigns directly without any engineering involvement.", "name": "Sarah Chen", "role": "VP of Engineering, ShopFlow"}
    },
    {
      "type": "testimonial",
      "props": {"quote": "We reduced our app size by 40% and eliminated the need for quarterly releases. Flutter + SDUI is the future of cross-platform development.", "name": "Marcus Rivera", "role": "CTO, FinClear"}
    },
    {
      "type": "testimonial",
      "props": {"quote": "Running A/B tests used to take a full sprint. Now we iterate daily. Our conversion rate improved 23% in the first month.", "name": "Priya Nair", "role": "Product Director, TravelEase"}
    },
    {
      "type": "sectionHeader",
      "props": {
        "title": "Pitfalls",
        "subtitle": "Avoid these common SDUI traps"
      }
    },
    {
      "type": "pitfallGrid",
      "props": {},
      "children": [
        {"type": "pitfallCard", "props": {"icon": "puzzle", "title": "Over-Engineering Schema", "description": "Start with 10-12 components covering 80% of use cases. Add types only when usage data justifies them."}},
        {"type": "pitfallCard", "props": {"icon": "flame", "title": "Performance Regressions", "description": "Enforce depth limits, pre-measure lists, paginate by default. Profile regularly on low-end devices."}},
        {"type": "pitfallCard", "props": {"icon": "palette", "title": "Inconsistent Design", "description": "Codify design tokens in the client. Expose token names in schema, not raw hex codes."}},
        {"type": "pitfallCard", "props": {"icon": "shield_off", "title": "Security & Injection", "description": "Validate schemas strictly. Whitelist types and props. Sanitize URLs. Require signed schemas."}},
        {"type": "pitfallCard", "props": {"icon": "alert_triangle", "title": "Breaking Old Clients", "description": "Use semantic schema_version. Build compatibility gates and fallbacks for older app builds."}},
        {"type": "pitfallCard", "props": {"icon": "users", "title": "Blurred Ownership", "description": "Assign clear ownership for registry and governance. Document who adds components and launches experiments."}},
        {"type": "pitfallCard", "props": {"icon": "bug", "title": "Testing Gaps", "description": "Contract linting in CI. Seed data for rare states. Weekly smoke tests of top 20 schemas."}},
        {"type": "pitfallCard", "props": {"icon": "alert_circle", "title": "Silver Bullet Trap", "description": "Not every screen needs SDUI. Use hybrid: dynamic for marketing/onboarding, native for performance-critical flows."}}
      ]
    },
    {
      "type": "statsRow",
      "props": {},
      "children": [
        {"type": "statItem", "props": {"value": "10x", "label": "Faster UI Updates"}},
        {"type": "statItem", "props": {"value": "0", "label": "App Store Delays"}},
        {"type": "statItem", "props": {"value": "40%", "label": "Lower Engineering Costs"}},
        {"type": "statItem", "props": {"value": "100%", "label": "Cross-Platform"}}
      ]
    },
    {
      "type": "sectionHeader",
      "props": {
        "title": "FAQ",
        "subtitle": "Everything you need to know"
      }
    },
    {
      "type": "faqItem",
      "props": {"question": "What is SDUI exactly?", "answer": "Server-Driven UI is a design approach where the UI structure is dictated by the server instead of being hardcoded. The app fetches JSON instructions from the backend and renders the UI dynamically."}
    },
    {
      "type": "faqItem",
      "props": {"question": "How is SDUI different from traditional dev?", "answer": "Every UI change in traditional development requires an app rebuild and store approval. With SDUI, updates happen instantly from the server with no app store involvement."}
    },
    {
      "type": "faqItem",
      "props": {"question": "Does SDUI work offline?", "answer": "Yes. Schemas are cached on the device so critical screens render without a network connection. A well-designed SDUI system includes an offline rendering set for core functionality."}
    },
    {
      "type": "faqItem",
      "props": {"question": "Is SDUI secure?", "answer": "When implemented correctly, absolutely. Best practices include strict schema validation, whitelisted component types, sanitized URLs, and signed schemas for sensitive flows."}
    },
    {
      "type": "faqItem",
      "props": {"question": "Does SDUI affect performance?", "answer": "Not when done right. Flutter handles dynamic widget trees just as efficiently as static ones. Performance guardrails like depth limits and lazy loading ensure a snappy experience."}
    },
    {
      "type": "faqItem",
      "props": {"question": "Can I use SDUI for part of my app?", "answer": "Absolutely. The winning approach is hybrid: make change-heavy surfaces like marketing and onboarding server-driven, while keeping performance-critical features hand-coded."}
    },
    {
      "type": "faqItem",
      "props": {"question": "How do I handle schema versioning?", "answer": "Include a schema_version field at the root. Introduce new features with a version bump. Build a compatibility layer so older clients fall back gracefully."}
    },
    {
      "type": "faqItem",
      "props": {"question": "What team do I need?", "answer": "A small team owning the widget registry and schema governance. Product managers and designers can brief changes directly in SDUI terms once the system is established."}
    },
    {
      "type": "cta",
      "props": {
        "headline": "Ready to Make Your UI Dynamic?",
        "subtitle": "Start with one screen. Prove the cycle time improvement. Then scale with intent. The future of agile UI starts here.",
        "buttonText": "Book a Consultation",
        "linkText": "View Documentation \u2192"
      }
    }
  ]
}
''';
