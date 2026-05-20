CREATE TABLE IF NOT EXISTS `w2f_pawnshop_stock` (
    `item` VARCHAR(64) NOT NULL,
    `quantity` INT NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`item`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `w2f_pawnshop_transactions` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(128) NOT NULL,
    `item` VARCHAR(64) NOT NULL,
    `amount` INT NOT NULL,
    `unit_price` INT NOT NULL,
    `total_price` INT NOT NULL,
    `type` VARCHAR(16) NOT NULL DEFAULT 'sell',
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `idx_identifier` (`identifier`),
    KEY `idx_item` (`item`),
    KEY `idx_created` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `w2f_pawnshop_loyalty` (
    `identifier` VARCHAR(128) NOT NULL,
    `xp` INT NOT NULL DEFAULT 0,
    `level` TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `total_sold` INT NOT NULL DEFAULT 0,
    `total_bought` INT NOT NULL DEFAULT 0,
    `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
