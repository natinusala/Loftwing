@_exported import CYoga

/// Replaces the YGUndefined define. Safe to use because
/// Yoga internally calls std::isnan.
fileprivate let YGUndefined = Float.nan
