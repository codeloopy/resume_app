class RemoveOrphanedMigration < ActiveRecord::Migration[7.2]
  def up
    # Remove the orphaned migration entry if it exists
    execute "DELETE FROM schema_migrations WHERE version = '20250618174134'"
  end

  def down
    # Add it back if we need to rollback (though this shouldn't be necessary)
    execute "INSERT INTO schema_migrations (version) VALUES ('20250618174134')"
  end
end
