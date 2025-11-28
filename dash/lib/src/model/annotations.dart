/// Runtime types for Dash models.
///
/// These types are used at runtime for relationship metadata
/// and model introspection. Model code generation is handled
/// by YAML schemas, not annotations.
library;

/// Types of relationships between models.
enum RelationshipType { belongsTo, hasOne, hasMany }

/// Metadata about a model relationship.
///
/// This class holds runtime information about relationships
/// that is used for eager loading and relation resolution.
class RelationshipMeta {
  /// The name of the relationship field (e.g., 'author').
  final String name;

  /// The type of relationship.
  final RelationshipType type;

  /// The foreign key column name.
  final String foreignKey;

  /// The related key column (owner key for BelongsTo, local key for HasOne/HasMany).
  final String relatedKey;

  /// The type of the related model as a string.
  final String relatedModelType;

  const RelationshipMeta({
    required this.name,
    required this.type,
    required this.foreignKey,
    required this.relatedKey,
    required this.relatedModelType,
  });
}
