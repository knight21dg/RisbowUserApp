import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/utils/widgets/custom_toast.dart';
import '../model/sdui_schema.dart';

final Map<String, IconData> _iconMap = {
  'bolt': TablerIcons.bolt,
  'code': TablerIcons.code,
  'device_mobile': TablerIcons.device_mobile,
  'refresh': TablerIcons.refresh,
  'layout_grid': TablerIcons.layout_grid,
  'devices': TablerIcons.devices,
  'layers_difference': TablerIcons.layers_difference,
  'users': TablerIcons.users,
  'coin': TablerIcons.coin,
  'flask': TablerIcons.flask,
  'shield_check': TablerIcons.shield_check,
  'globe': TablerIcons.globe,
  'server_2': TablerIcons.server_2,
  'file_code': TablerIcons.file_code,
  'api': TablerIcons.api,
  'database': TablerIcons.database,
  'shield': TablerIcons.shield,
  'eye': TablerIcons.eye,
  'shopping_cart': TablerIcons.shopping_cart,
  'building_bank': TablerIcons.building_bank,
  'backpack': TablerIcons.backpack,
  'news': TablerIcons.news,
  'plane': TablerIcons.plane,
  'heart': TablerIcons.heart,
  'briefcase': TablerIcons.briefcase,
  'puzzle': TablerIcons.puzzle,
  'flame': TablerIcons.flame,
  'palette': TablerIcons.palette,
  'shield_off': TablerIcons.shield_off,
  'alert_triangle': TablerIcons.alert_triangle,
  'bug': TablerIcons.bug,
  'alert_circle': TablerIcons.alert_circle,
  'circle_check': TablerIcons.circle_check,
  'arrow_right_circle': TablerIcons.arrow_right_circle,
  'quote': TablerIcons.quote,
  'trending_up': TablerIcons.trending_up,
  'check': TablerIcons.check,
  'x': TablerIcons.x,
  'chevron_down': TablerIcons.chevron_down,
};

IconData _icon(String name) =>
    _iconMap[name] ?? TablerIcons.question_mark;

/// Maps JSON schema types → Flutter widgets.
/// This is the rendering engine the server controls.
class SduiRegistry {
  const SduiRegistry._();

  /// Renders a single SduiNode into a Flutter widget.
  static Widget render(SduiNode node, BuildContext context) {
    switch (node.type) {
      case 'hero':
        return _HeroWidget(node.props);
      case 'sectionHeader':
        return _SectionHeaderWidget(node.props);
      case 'comparisonTable':
        return _ComparisonTableWidget(node, context);
      case 'infoCard':
        return _InfoCardWidget(node.props, context);
      case 'miniCard':
        return _MiniCardWidget(node.props, context);
      case 'step':
        return _StepWidget(node.props, context);
      case 'stepCompact':
        return _StepCompactWidget(node.props, context);
      case 'codeBlock':
        return _CodeBlockWidget(node.props, context);
      case 'benefitGrid':
        return _BenefitGridWidget(node, context);
      case 'architectureLayer':
        return _ArchitectureLayerWidget(node.props, context);
      case 'useCase':
        return _UseCaseWidget(node.props, context);
      case 'testimonial':
        return _TestimonialWidget(node.props, context);
      case 'pitfallGrid':
        return _PitfallGridWidget(node, context);
      case 'statsRow':
        return _StatsRowWidget(node, context);
      case 'faqItem':
        return _FaqItemWidget(node.props);
      case 'cta':
        return _CtaWidget(node.props);
      default:
        return SizedBox.shrink();
    }
  }

  /// Renders a list of sections with alternating backgrounds.
  static List<Widget> renderSections(
      List<SduiNode> sections, BuildContext context) {
    final List<Widget> out = [];
    int normalIndex = 0;
    for (final section in sections) {
      final widget = render(section, context);
      if (section.type == 'sectionHeader' ||
          section.type == 'hero' ||
          section.type == 'codeBlock' ||
          section.type == 'statsRow' ||
          section.type == 'cta') {
        out.add(widget);
        continue;
      }
      final isAlt = normalIndex % 2 == 1;
      normalIndex++;
      if (isAlt) {
        out.add(Container(
          width: double.infinity,
          color: Theme.of(context).brightness == Brightness.dark
              ? AppTheme.primaryColor.withValues(alpha: 0.05)
              : const Color(0xFFF8FAFF),
          child: widget,
        ));
      } else {
        out.add(widget);
      }
    }
    return out;
  }
}

// ─── Widget Builders ────────────────────────────────────────

class _HeroWidget extends StatelessWidget {
  final Map<String, dynamic> p;
  const _HeroWidget(this.p);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chips = (p['chips'] as List<dynamic>?)?.cast<String>() ?? [];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 48.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [AppTheme.primaryColor.withValues(alpha: 0.25), const Color(0xFF0D1117), AppTheme.primaryColor.withValues(alpha: 0.15)]
              : [AppTheme.primaryColor.withValues(alpha: 0.08), Colors.white, AppTheme.primaryColor.withValues(alpha: 0.05)],
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 32.h),
          _badge(p['badge'] as String? ?? '', _icon(p['badgeIcon'] as String? ?? 'bolt')),
          SizedBox(height: 24.h),
          ShaderMask(
            shaderCallback: (b) => LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.7), const Color(0xFF64B5F6)]).createShader(b),
            blendMode: BlendMode.srcIn,
            child: Text(p['headline'] as String? ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w800, height: 1.2, color: Colors.white)),
          ),
          SizedBox(height: 16.h),
          Text(p['subtitle'] as String? ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 13.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), height: 1.5)),
          SizedBox(height: 28.h),
          Wrap(spacing: 8.w, runSpacing: 8.h, alignment: WrapAlignment.center,
              children: chips.map((c) => _chip(c)).toList()),
          SizedBox(height: 32.h),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => _handleCta(context, p['cta'] as String? ?? ''),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: 14.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), elevation: 0),
            child: Text(p['cta'] as String? ?? '', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
          )),
        ],
      ),
    );
  }
}

class _SectionHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> p;
  const _SectionHeaderWidget(this.p);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = p['body'] as String?;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
      child: Column(
        children: [
          _badge(p['title'] as String? ?? '', null),
          SizedBox(height: 10.h),
          Text(p['subtitle'] as String? ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700, height: 1.2)),
          if (body != null) ...[
            SizedBox(height: 12.h),
            Text(body, textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), height: 1.5)),
          ],
        ],
      ),
    );
  }
}

class _ComparisonTableWidget extends StatelessWidget {
  final SduiNode node;
  final BuildContext ctx;
  const _ComparisonTableWidget(this.node, this.ctx);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final rows = node.children ?? [];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 32.h),
      color: isDark ? AppTheme.primaryColor.withValues(alpha: 0.05) : const Color(0xFFF8FAFF),
      child: Column(
        children: [
          _badge(node.props['title'] as String? ?? '', null),
          SizedBox(height: 10.h),
          Text(node.props['subtitle'] as String? ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700, height: 1.2)),
          SizedBox(height: 20.h),
          Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.r), border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.12))),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Column(
                children: [
                  Container(padding: EdgeInsets.symmetric(vertical: 10.h), color: AppTheme.primaryColor.withValues(alpha: 0.08),
                    child: Row(children: [
                      SizedBox(width: 12.w),
                      Expanded(flex: 3, child: Text('', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, color: AppTheme.primaryColor))),
                      Expanded(flex: 4, child: Text('Traditional', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, color: AppColors.error))),
                      Expanded(flex: 4, child: Text('SDUI', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600, color: AppColors.success))),
                      SizedBox(width: 12.w),
                    ]),
                  ),
                  ...List.generate(rows.length, (i) {
                    final r = rows[i].props;
                    return Container(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      color: i.isEven ? (isDark ? Colors.white.withValues(alpha: 0.02) : Colors.grey.withValues(alpha: 0.04)) : null,
                      child: Row(children: [
                        SizedBox(width: 12.w),
                        Expanded(flex: 3, child: Text(r['label'] as String? ?? '', style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500))),
                        Expanded(flex: 4, child: Row(children: [
                          Icon(TablerIcons.x, size: 12.sp, color: AppColors.error),
                          SizedBox(width: 4.w),
                          Expanded(child: Text(r['traditional'] as String? ?? '', style: TextStyle(fontSize: 9.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)))),
                        ])),
                        Expanded(flex: 4, child: Row(children: [
                          Icon(TablerIcons.check, size: 12.sp, color: AppColors.success),
                          SizedBox(width: 4.w),
                          Expanded(child: Text(r['sdui'] as String? ?? '', style: TextStyle(fontSize: 9.sp, color: AppColors.success, fontWeight: FontWeight.w500))),
                        ])),
                        SizedBox(width: 12.w),
                      ]),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCardWidget extends StatelessWidget {
  final Map<String, dynamic> p;
  final BuildContext ctx;
  const _InfoCardWidget(this.p, this.ctx);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r), side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.12))),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 44.w, height: 44.w, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12.r)),
                child: Icon(_icon(p['icon'] as String? ?? ''), size: 22.sp, color: AppTheme.primaryColor)),
            SizedBox(width: 14.w),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['title'] as String? ?? '', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 4.h),
              Text(p['description'] as String? ?? '', style: TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), height: 1.4)),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _MiniCardWidget extends StatelessWidget {
  final Map<String, dynamic> p;
  final BuildContext ctx;
  const _MiniCardWidget(this.p, this.ctx);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r), side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.12))),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(_icon(p['icon'] as String? ?? ''), size: 22.sp, color: AppTheme.primaryColor),
            SizedBox(width: 12.w),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['title'] as String? ?? '', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 2.h),
              Text(p['description'] as String? ?? '', style: TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), height: 1.4)),
            ])),
          ]),
        ),
      ),
    );
  }
}

class _StepWidget extends StatelessWidget {
  final Map<String, dynamic> p;
  final BuildContext ctx;
  const _StepWidget(this.p, this.ctx);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 40.w, height: 40.w,
            decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [BoxShadow(color: AppTheme.primaryColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))]),
            alignment: Alignment.center,
            child: Text(p['step'] as String? ?? '', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: Colors.white))),
        SizedBox(width: 14.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p['title'] as String? ?? '', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 4.h),
          Text(p['description'] as String? ?? '', style: TextStyle(fontSize: 12.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), height: 1.4)),
        ])),
      ]),
    );
  }
}

class _StepCompactWidget extends StatelessWidget {
  final Map<String, dynamic> p;
  final BuildContext ctx;
  const _StepCompactWidget(this.p, this.ctx);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 28.w, height: 28.w,
            decoration: BoxDecoration(color: isDark ? AppTheme.primaryColor.withValues(alpha: 0.2) : AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14.r)),
            alignment: Alignment.center,
            child: Text('${p['num']}', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: AppTheme.primaryColor))),
        SizedBox(width: 12.w),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(p['title'] as String? ?? '', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 2.h),
          Text(p['description'] as String? ?? '', style: TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), height: 1.4)),
        ])),
      ]),
    );
  }
}

class _CodeBlockWidget extends StatelessWidget {
  final Map<String, dynamic> p;
  final BuildContext ctx;
  const _CodeBlockWidget(this.p, this.ctx);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final code = p['code'] as String? ?? '';
    final caption = p['caption'] as String? ?? '';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Column(
        children: [
          Container(width: double.infinity, padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFF0D1117), borderRadius: BorderRadius.circular(12.r)),
              child: SelectableText(code, style: TextStyle(fontSize: 10.sp, fontFamily: 'monospace', height: 1.5, color: const Color(0xFF98C379)))),
          if (caption.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(_icon('arrow_right_circle'), size: 14.sp, color: AppColors.success),
              SizedBox(width: 6.w),
              Text(caption, style: TextStyle(fontSize: 9.sp, color: AppColors.success, fontWeight: FontWeight.w500)),
            ]),
          ],
        ],
      ),
    );
  }
}

class _BenefitGridWidget extends StatelessWidget {
  final SduiNode node;
  final BuildContext ctx;
  const _BenefitGridWidget(this.node, this.ctx);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = node.children ?? [];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Wrap(spacing: 10.w, runSpacing: 10.h,
        children: children.map((c) {
          final pr = c.props;
          return SizedBox(
            width: (MediaQuery.of(context).size.width - 50.w) / 2,
            child: Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r), side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.15))),
              child: Padding(padding: EdgeInsets.all(14.w), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(_icon(pr['icon'] as String? ?? ''), size: 22.sp, color: AppTheme.primaryColor),
                SizedBox(height: 10.h),
                Text(pr['title'] as String? ?? '', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
                SizedBox(height: 4.h),
                Text(pr['description'] as String? ?? '', style: TextStyle(fontSize: 10.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), height: 1.4)),
              ])),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ArchitectureLayerWidget extends StatelessWidget {
  final Map<String, dynamic> p;
  final BuildContext ctx;
  const _ArchitectureLayerWidget(this.p, this.ctx);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = (p['items'] as List<dynamic>?)?.cast<String>() ?? [];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      child: Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r), side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.15))),
        child: Padding(padding: EdgeInsets.all(16.w), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 40.w, height: 40.w, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10.r)),
                child: Icon(_icon(p['icon'] as String? ?? ''), size: 20.sp, color: AppTheme.primaryColor)),
            SizedBox(width: 10.w),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['layer'] as String? ?? '', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
              Text(p['tag'] as String? ?? '', style: TextStyle(fontSize: 10.sp, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
            ]),
          ]),
          SizedBox(height: 10.h),
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
          SizedBox(height: 10.h),
          ...items.map((item) => Padding(padding: EdgeInsets.only(bottom: 4.h), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(TablerIcons.circle_check, size: 12.sp, color: AppTheme.primaryColor),
            SizedBox(width: 8.w),
            Expanded(child: Text(item, style: TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6)))),
          ]))),
        ])),
      ),
    );
  }
}

class _UseCaseWidget extends StatelessWidget {
  final Map<String, dynamic> p;
  final BuildContext ctx;
  const _UseCaseWidget(this.p, this.ctx);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      child: Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r), side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.12))),
        child: Padding(padding: EdgeInsets.all(14.w), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 36.w, height: 36.w, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10.r)),
                child: Icon(_icon(p['icon'] as String? ?? ''), size: 18.sp, color: AppTheme.primaryColor)),
            SizedBox(width: 12.w),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['industry'] as String? ?? '', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 4.h),
              Text(p['description'] as String? ?? '', style: TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), height: 1.4)),
            ])),
          ]),
          if (p['impact'] != null) ...[
            SizedBox(height: 8.h),
            Container(padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6.r)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(TablerIcons.trending_up, size: 10.sp, color: AppColors.success),
                  SizedBox(width: 4.w),
                  Text('Impact: ${p['impact']}', style: TextStyle(fontSize: 9.sp, color: AppColors.success, fontWeight: FontWeight.w500)),
                ])),
          ],
        ])),
      ),
    );
  }
}

class _TestimonialWidget extends StatelessWidget {
  final Map<String, dynamic> p;
  final BuildContext ctx;
  const _TestimonialWidget(this.p, this.ctx);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      child: Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r), side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.12))),
        child: Padding(padding: EdgeInsets.all(16.w), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(TablerIcons.quote, size: 20.sp, color: AppTheme.primaryColor.withValues(alpha: 0.3)),
          SizedBox(height: 8.h),
          Text('\u201c${p['quote'] as String? ?? ''}\u201d', style: TextStyle(fontSize: 12.sp, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withValues(alpha: 0.8), height: 1.4)),
          SizedBox(height: 10.h),
          Row(children: [
            Container(width: 32.w, height: 32.w, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16.r)),
                alignment: Alignment.center,
                child: Text((p['name'] as String? ?? '')[0], style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, color: AppTheme.primaryColor))),
            SizedBox(width: 10.w),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p['name'] as String? ?? '', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600)),
              Text(p['role'] as String? ?? '', style: TextStyle(fontSize: 10.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            ]),
          ]),
        ])),
      ),
    );
  }
}

class _PitfallGridWidget extends StatelessWidget {
  final SduiNode node;
  final BuildContext ctx;
  const _PitfallGridWidget(this.node, this.ctx);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final children = node.children ?? [];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Wrap(spacing: 10.w, runSpacing: 10.h,
        children: children.map((c) {
          final pr = c.props;
          return SizedBox(
            width: (MediaQuery.of(context).size.width - 50.w) / 2,
            child: Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r), side: BorderSide(color: AppColors.error.withValues(alpha: 0.15))),
              child: Padding(padding: EdgeInsets.all(12.w), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(_icon(pr['icon'] as String? ?? ''), size: 16.sp, color: AppColors.error),
                  SizedBox(width: 6.w),
                  Expanded(child: Text(pr['title'] as String? ?? '', style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600))),
                ]),
                SizedBox(height: 6.h),
                Text(pr['description'] as String? ?? '', style: TextStyle(fontSize: 10.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), height: 1.4)),
              ])),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatsRowWidget extends StatelessWidget {
  final SduiNode node;
  final BuildContext ctx;
  const _StatsRowWidget(this.node, this.ctx);

  @override
  Widget build(BuildContext context) {
    final children = node.children ?? [];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Container(
        width: double.infinity, padding: EdgeInsets.symmetric(vertical: 24.h),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryColor.withValues(alpha: 0.1), AppTheme.primaryColor.withValues(alpha: 0.05)]), borderRadius: BorderRadius.circular(16.r)),
        child: Row(children: children.map((c) {
          final pr = c.props;
          return Expanded(child: Column(children: [
            Text(pr['value'] as String? ?? '', style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w800, color: AppTheme.primaryColor)),
            SizedBox(height: 4.h),
            Text(pr['label'] as String? ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 10.sp, color: Colors.grey)),
          ]));
        }).toList()),
      ),
    );
  }
}

class _FaqItemWidget extends StatefulWidget {
  final Map<String, dynamic> p;
  const _FaqItemWidget(this.p);

  @override
  State<_FaqItemWidget> createState() => _FaqItemWidgetState();
}

class _FaqItemWidgetState extends State<_FaqItemWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      child: Card(elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r), side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.12))),
        child: InkWell(borderRadius: BorderRadius.circular(12.r), onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(padding: EdgeInsets.all(14.w), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(widget.p['question'] as String? ?? '', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500))),
              AnimatedRotation(turns: _expanded ? 0.5 : 0, duration: const Duration(milliseconds: 200),
                  child: Icon(TablerIcons.chevron_down, size: 16.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
            ]),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(padding: EdgeInsets.only(top: 10.h),
                  child: Text(widget.p['answer'] as String? ?? '', style: TextStyle(fontSize: 11.sp, color: theme.colorScheme.onSurface.withValues(alpha: 0.6), height: 1.4))),
              crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ]),
        ),
      ),
      ),
    );
  }
}

class _CtaWidget extends StatelessWidget {
  final Map<String, dynamic> p;
  const _CtaWidget(this.p);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: Container(
        width: double.infinity, padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryColor, const Color(0xFF0D47A1)]), borderRadius: BorderRadius.circular(16.r)),
        child: Column(children: [
          Text(p['headline'] as String? ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700, color: Colors.white)),
          SizedBox(height: 12.h),
          Text(p['subtitle'] as String? ?? '', textAlign: TextAlign.center, style: TextStyle(fontSize: 12.sp, color: Colors.white.withValues(alpha: 0.8), height: 1.4)),
          SizedBox(height: 20.h),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () => _handleCta(context, p['buttonText'] as String? ?? ''),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppTheme.primaryColor, padding: EdgeInsets.symmetric(vertical: 14.h), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), elevation: 0),
            child: Text(p['buttonText'] as String? ?? '', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
          )),
          if (p['linkText'] != null) ...[
            SizedBox(height: 8.h),
            TextButton(onPressed: () => _handleLink(context, p['linkText'] as String? ?? ''), child: Text(p['linkText'] as String? ?? '', style: TextStyle(fontSize: 12.sp, color: Colors.white.withValues(alpha: 0.7)))),
          ],
        ]),
      ),
    );
  }
}

// ─── Action Handlers ─────────────────────────────────────────

void _handleCta(BuildContext context, String label) {
  switch (label) {
    case 'Start Building':
    case 'Book a Consultation':
      ToastManager.show(
        context: context,
        message: 'Thanks for your interest! This feature is coming soon.',
        type: ToastType.info,
      );
      break;
    case 'Get Started':
      ToastManager.show(
        context: context,
        message: 'Welcome! Explore the app to get started.',
        type: ToastType.success,
      );
      break;
    case 'Scroll Down':
      ToastManager.show(
        context: context,
        message: 'Scroll down to explore all SDUI components!',
        type: ToastType.info,
      );
      break;
    default:
      ToastManager.show(
        context: context,
        message: label,
        type: ToastType.info,
      );
  }
}

void _handleLink(BuildContext context, String label) {
  switch (label) {
    case 'View Documentation →':
      context.push('/custom-sale-page/documentation');
      break;
    default:
      ToastManager.show(
        context: context,
        message: 'Navigating to $label',
        type: ToastType.info,
      );
  }
}

// ─── Shared helpers ─────────────────────────────────────────

Widget _badge(String label, IconData? icon) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
    decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20.r)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 14.sp, color: AppTheme.primaryColor), SizedBox(width: 6.w)],
      Text(label, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
    ]),
  );
}

Widget _chip(String label) {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
    decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16.r)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(TablerIcons.circle_check, size: 12.sp, color: AppTheme.primaryColor),
      SizedBox(width: 4.w),
      Text(label, style: TextStyle(fontSize: 10.sp, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
    ]),
  );
}
