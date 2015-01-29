class PermissionDiffer
  def self.diff(old_perms, new_perms)
    old_perms = build_perms_hash(old_perms)
    new_perms = build_perms_hash(new_perms)

    app_names = (old_perms.keys + new_perms.keys).uniq

    {
      added: diff_perms_hashes(app_names, new_perms, old_perms),
      removed: diff_perms_hashes(app_names, old_perms, new_perms)
    }
  end

private

  def self.build_perms_hash(perms)
    perms_hash = Hash.new {|hash, key| hash[key] = [] }

    perms.each do |permission|
      perms_hash[permission.application.name] << permission.supported_permission.name
    end

    perms_hash
  end

  def self.diff_perms_hashes(app_names, perms_1, perms_2)
    app_names.inject({}) do |diff, app_name|
      app_diff = perms_1[app_name] - perms_2[app_name]

      if app_diff.any?
        diff.merge(app_name => app_diff)
      else
        diff
      end
    end
  end
end
