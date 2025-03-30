-- Desactivar restricciones para evitar problemas durante la creación de las tablas
SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Crear la base de datos StockX
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `StockX` DEFAULT CHARACTER SET utf8;
USE `StockX`;

-- -----------------------------------------------------
-- Tabla `Usuario`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `StockX`.`Usuario` (
  `ID_Usuario` INT NOT NULL AUTO_INCREMENT,
  `Nickname` VARCHAR(45) NOT NULL,
  `Nombre` VARCHAR(45) NOT NULL,
  `Apellidos` VARCHAR(45) NOT NULL,
  `Talla` INT NOT NULL,
  `Email` VARCHAR(45) NOT NULL,
  `Direccion_envio` VARCHAR(45) NULL,
  `Nivel_de_vendedor` VARCHAR(45) NOT NULL,
  PRIMARY KEY (`ID_Usuario`),
  UNIQUE INDEX `idx_unique_nickname` (`Nickname`)
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Tabla `Cartera`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `StockX`.`Cartera` (
  `ID_Cartera` INT NOT NULL AUTO_INCREMENT,
  `Info_de_compras` VARCHAR(200) NULL,
  `Info_de_vendedor` VARCHAR(200) NULL,
  `Info_de_pago` VARCHAR(200) NULL,
  `Saldo_tarjeta_credito` FLOAT NULL,
  `Saldo_tarjeta_regalo` FLOAT NULL,
  `ID_Usuario` INT NOT NULL,
  PRIMARY KEY (`ID_Cartera`),
  INDEX `fk_Cartera_Usuario1_idx` (`ID_Usuario` ASC) VISIBLE,
  CONSTRAINT `fk_Cartera_Usuario1`
    FOREIGN KEY (`ID_Usuario`)
    REFERENCES `StockX`.`Usuario` (`ID_Usuario`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Tabla `Compras`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `StockX`.`Compras` (
  `ID_Compra` INT NOT NULL AUTO_INCREMENT,
  `Fecha_de_compra` DATE DEFAULT NULL,
  `Precio_de_compra` FLOAT NOT NULL,
  `Envio_rapido` TINYINT(1) NOT NULL,
  `ID_Usuario_Vendedor` INT NOT NULL,
  `ID_Cartera_Comprador` INT NOT NULL,
  PRIMARY KEY (`ID_Compra`),
  INDEX `fk_Compras_Usuario1_idx` (`ID_Usuario_Vendedor` ASC) VISIBLE,
  INDEX `fk_Compras_Cartera1_idx` (`ID_Cartera_Comprador` ASC) VISIBLE,
  CONSTRAINT `fk_Compras_Cartera1`
    FOREIGN KEY (`ID_Cartera_Comprador`)
    REFERENCES `StockX`.`Cartera` (`ID_Cartera`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Compras_Usuario1`
    FOREIGN KEY (`ID_Usuario_Vendedor`)
    REFERENCES `StockX`.`Usuario` (`ID_Usuario`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB AUTO_INCREMENT=508 DEFAULT CHARSET=utf8mb3;

-- -----------------------------------------------------
-- Tabla `Producto_Neto`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `StockX`.`Producto_Neto` (
  `ID_Producto` INT NOT NULL AUTO_INCREMENT,
  `Tipo_de_producto` VARCHAR(45) NOT NULL,
  `Marca` VARCHAR(45) NOT NULL,
  `Detalles_del_producto` VARCHAR(200) NULL,
  `Modelo` VARCHAR(60) NOT NULL,
  `Precio_retail` FLOAT NULL,
  PRIMARY KEY (`ID_Producto`)
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Tabla `Producto_Ventas`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `StockX`.`Producto_Ventas` (
  `Precio` FLOAT NOT NULL,
  `Talla` INT NOT NULL,
  `ID_Producto` INT NOT NULL,
  `ID_Compra` INT NOT NULL,
  PRIMARY KEY (`ID_Producto`, `ID_Compra`),
  INDEX `fk_Producto_Ventas_Producto_Neto1_idx` (`ID_Producto` ASC) VISIBLE,
  INDEX `fk_Producto_Ventas_Compras1_idx` (`ID_Compra` ASC) VISIBLE,
  CONSTRAINT `fk_Producto_Ventas_Producto_Neto1`
    FOREIGN KEY (`ID_Producto`)
    REFERENCES `StockX`.`Producto_Neto` (`ID_Producto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Producto_Ventas_Compras1`
    FOREIGN KEY (`ID_Compra`)
    REFERENCES `StockX`.`Compras` (`ID_Compra`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Tabla `Favoritos`
-- -----------------------------------------------------
CREATE TABLE IF NOT EXISTS `StockX`.`Favoritos` (
  `ID_Usuario` INT NOT NULL,
  `ID_Producto` INT NOT NULL,
  PRIMARY KEY (`ID_Usuario`, `ID_Producto`),
  INDEX `fk_Usuario_has_Producto_Neto_Producto_Neto1_idx` (`ID_Producto` ASC) VISIBLE,
  INDEX `fk_Usuario_has_Producto_Neto_Usuario1_idx` (`ID_Usuario` ASC) VISIBLE,
  CONSTRAINT `fk_Usuario_has_Producto_Neto_Usuario1`
    FOREIGN KEY (`ID_Usuario`)
    REFERENCES `StockX`.`Usuario` (`ID_Usuario`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_Usuario_has_Producto_Neto_Producto_Neto1`
    FOREIGN KEY (`ID_Producto`)
    REFERENCES `StockX`.`Producto_Neto` (`ID_Producto`)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
)
ENGINE = InnoDB;

-- -----------------------------------------------------
-- Revertir configuración a la original
SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
