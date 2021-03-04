# Copyright © 2017-2020 The Axentro Core developers
#
# See the LICENSE file at the top-level directory of this distribution
# for licensing information.
#
# Unless otherwise agreed in a custom licensing agreement with the Axentro Core developers,
# no part of this software, including this file, may be copied, modified,
# propagated, or distributed except according to the terms contained in the
# LICENSE file.
#
# Removal or modification of this copyright notice is prohibited.

@[MG::Tags("main")]
class AddMerkleRootToArchive < MG::Base
  def up : String
    <<-SQL
      ALTER TABLE archived_blocks ADD COLUMN merkle_tree_root TEXT NOT NULL DEFAULT "0"
    SQL
  end

  def down : String
    # sqlite3 does not support drop column so have to do this
    <<-SQL
      CREATE TEMPORARY TABLE archived_blocks_temporary (
        block_hash             TEXT NOT NULL,
        archive_timestamp      INTEGER NOT NULL,
        reason                 TEXT NOT NULL,
        idx                    INTEGER PRIMARY KEY,
        nonce                  TEXT NOT NULL,
        prev_hash              TEXT NOT NULL,
        timestamp              INTEGER NOT NULL,
        difficulty             INTEGER NOT NULL,
        address                TEXT NOT NULL,
        kind                   TEXT NOT NULL,
        public_key             TEXT NOT NULL,
        signature              TEXT NOT NULL,
        hash                   TEXT NOT NULL,
        version                TEXT NOT NULL,
        hash_version           TEXT NOT NULL,
        merkle_tree_root       TEXT NOT NULL
      );
      INSERT INTO archived_blocks_temporary SELECT * FROM archived_blocks;
    DROP TABLE archived_blocks;
    CREATE TABLE archived_blocks (
      block_hash             TEXT NOT NULL,
      archive_timestamp      INTEGER NOT NULL,
      reason                 TEXT NOT NULL,
      idx                    INTEGER PRIMARY KEY,
      nonce                  TEXT NOT NULL,
      prev_hash              TEXT NOT NULL,
      timestamp              INTEGER NOT NULL,
      difficulty             INTEGER NOT NULL,
      address                TEXT NOT NULL,
      kind                   TEXT NOT NULL,
      public_key             TEXT NOT NULL,
      signature              TEXT NOT NULL,
      hash                   TEXT NOT NULL,
      version                TEXT NOT NULL,
      hash_version           TEXT NOT NULL,
      );
      INSERT INTO archived_blocks SELECT block_hash, archive_timestamp, reason, idx, nonce, prev_hash, timestamp, difficulty, address, kind, public_key, signature, hash, version, hash_version
    FROM archived_blocks_temporary;
    DROP TABLE archived_blocks_temporary;
    SQL
  end
end
