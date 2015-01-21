class Note < ActiveRecord::Base
  self.inheritance_column = nil

  TYPES = {
    training: "Training",
    permission_granted: "Permission granted",
    permission_removed: "Permission removed",
    disciplinary_action: "Disciplinary action",
    other: "Other event"
  }.freeze
end
