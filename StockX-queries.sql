-- Consultas
-- 1. Articulos que se venden a mayor precio que su precio de salida
select Modelo, Precio_retail, avg(pv.Precio), TRUNCATE(AVG(pv.Precio)-Precio_retail,2) as Beneficio
from Producto_Neto pn 
inner join Producto_Ventas pv on pn.ID_Producto = pv.ID_Producto 
group by pn.Modelo, pn.Precio_retail
having Beneficio > 0
order by Beneficio asc;

-- 2. Articulo/s que mas se añaden a la lista de favoritos
select pn.Modelo , count(f.ID_Producto) as Favoritos
from Favoritos f inner join Producto_Neto pn on f.ID_Producto = pn.ID_Producto 
group by 1
having count(f.ID_Producto) >= all(
	select count(f.ID_Producto) 
	from Favoritos f 
	inner join Producto_Neto pn on f.ID_Producto = pn.ID_Producto 
	group by pn.Modelo);
/*Esta seria la misma consulta pero con limit*/
select pn.Modelo , count(f.ID_Producto) 
from Favoritos f inner join Producto_Neto pn on f.ID_Producto = pn.ID_Producto 
group by pn.Modelo 
order by count(f.ID_Producto) desc
limit 2;

-- 3. Tallas mas usadas para cada producto
select pn.Modelo, pv.Talla, count(pv.Talla) as Ventas
from Producto_Neto pn
inner join Producto_Ventas pv on pn.ID_Producto = pv.ID_Producto
group by pn.Modelo, pv.Talla
having count(pv.Talla) = all(
    select max(Talla_count)
    from (
        select count(pv2.Talla) as Talla_count
        from Producto_Ventas pv2
        inner join Producto_Neto pn2 on pn2.ID_Producto = pv2.ID_Producto
        where pn2.Modelo = pn.Modelo
        group by pv2.Talla
    ) as subconsulta
)
order by 3 desc;

-- 4. Nombre del usuario que mas ventas ha hecho
select c.ID_Usuario_Vendedor , u.Nombre ,count(ID_Usuario_Vendedor) as Ventas_Realizadas
from Compras c inner join Usuario u on c.ID_Usuario_Vendedor = u.ID_Usuario 
group by c.ID_Usuario_Vendedor 
having count(ID_Usuario_Vendedor) >= all(
	select count(ID_Usuario_Vendedor)
	from Compras c 
	inner join Usuario u on c.ID_Usuario_Vendedor = u.ID_Usuario 
	group by c.ID_Usuario_Vendedor);

-- 5. Usuarios que han comprado productos con tallas diferentes a la suya
SELECT u.ID_Usuario ,u.Talla as Talla_Usuario, pv.Talla as Talla_Comprada
from Usuario u 
inner join Cartera c on u.ID_Usuario = c.ID_Usuario 
inner join Compras cp on cp.ID_Cartera_Comprador = c.ID_Cartera 
inner join Producto_Ventas pv on pv.ID_Compra = cp.ID_Compra 
where u.Talla != pv.Talla;


-- Vistas
-- 1. Vista masVentas
create view masVentas as
select c.ID_Usuario_Vendedor , u.Nombre ,count(ID_Usuario_Vendedor) as Ventas_Realizadas
from Compras c inner join Usuario u on c.ID_Usuario_Vendedor = u.ID_Usuario 
group by c.ID_Usuario_Vendedor 
having count(ID_Usuario_Vendedor) >= all(
	select count(ID_Usuario_Vendedor)
	from Compras c 
	inner join Usuario u on c.ID_Usuario_Vendedor = u.ID_Usuario 
	group by c.ID_Usuario_Vendedor);
-- Comprobar
select * from masVentas mv;

-- 2. Vista Beneficios
create view Beneficios as
select Modelo, Precio_retail, avg(pv.Precio), TRUNCATE(AVG(pv.Precio)-Precio_retail,2) as Beneficio
from Producto_Neto pn 
inner join Producto_Ventas pv on pn.ID_Producto = pv.ID_Producto 
group by pn.Modelo, pn.Precio_retail
having Beneficio > 0
order by Beneficio asc;
-- Comprobar
select * from Beneficios b; 

-- Funciones
-- 1. Compras realizadas por la id seleccionada
delimiter //
create function comprasRealizadas(p_usuario_id int)
returns varchar(255)
deterministic
begin
    declare salida int default 0;
	/*Consulta*/
    select count(*) into salida
    from Compras cp
    inner join Cartera c on cp.ID_Cartera_Comprador = c.ID_Cartera 
    inner join Usuario u on u.ID_Usuario = c.ID_Usuario 
    where u.ID_Usuario = p_usuario_id;
	/*Return*/
    return concat('Este usuario ha realizado ', salida, ' compras');
end // 
delimiter ;
/*Select*/
select comprasRealizadas(4);

-- 2. Saldo total de un usuario
delimiter //
create function saldoTotal(p_usuario_id int)
returns varchar(255)
deterministic
begin
    declare salida decimal(30,2) default 0;
	/*Consulta*/
   	select sum(c.Saldo_tarjeta_credito)+sum(c.Saldo_tarjeta_regalo) as Saldo_Total into salida
	from Usuario u
	inner join Cartera c on c.ID_Usuario = u.ID_Usuario 
	where u.ID_Usuario = p_usuario_id;
	/*Return*/
    return concat('Saldo total: ',salida,'€');
end // 
delimiter ;
/*Select*/
select saldoTotal(2);


-- Procedimientos
-- 1. Saldo total de un usuario mejorado (Usa la funcion saldoTotal)
delimiter //
create procedure consultarSaldoUsuario(in p_usuario_id int)
begin
    declare p_saldo decimal(30,2);
    declare p_saldo_msg varchar(255);
    declare p_usuario_existe int;
    -- Verifica si el usuario existe
    select count(*) into p_usuario_existe from Usuario where ID_Usuario = p_usuario_id;
    if p_usuario_existe = 0 then
        -- Si el usuario no existe, muestra un mensaje de error
        select 'Error: El usuario no existe en la base de datos' as mensaje;
    else
        -- Obtiene el saldo total del usuario
        select sum(c.Saldo_tarjeta_credito) + sum(c.Saldo_tarjeta_regalo) 
        into p_saldo 
        from Cartera c
        where c.ID_Usuario = p_usuario_id;
        -- Resultado del saldo total medido con nivel
        if p_saldo > 1000 then
            set p_saldo_msg = concat('Saldo total: ', p_saldo, '€. Nivel: Alto');
        elseif p_saldo between 500 and 1000 then
            set p_saldo_msg = concat('Saldo total: ', p_saldo, '€. Nivel: Medio');
        else
            set p_saldo_msg = concat('Saldo total: ', p_saldo, '€. Nivel: Bajo');
        end if;
        -- Mostrar resultado
        select p_saldo_msg as saldo;
    end if;
end //
delimiter ;
-- Llamada a el procedimiento
call consultarSaldoUsuario(3);

-- 2. Agregar producto a favoritos de un usuario
delimiter //
create procedure agregarAFavoritos(in p_id_usuario int, in p_id_producto int)
begin
    declare p_usuario_existe int;
    declare p_producto_existe int;
    declare p_favorito_existe int;
    declare p_modelo_producto varchar(60);
    -- Verifica si el usuario existe
    select count(*) into p_usuario_existe from Usuario where ID_Usuario = p_id_usuario;
    -- Verifica si el producto existe
    select count(*) into p_producto_existe from Producto_Neto where ID_Producto = p_id_producto;
    -- Obtiene modelo del producto si existe
    if p_producto_existe > 0 then
        select Modelo into p_modelo_producto from Producto_Neto where ID_Producto = p_id_producto;
    end if;
    -- Verifica si el producto ya está en favoritos
    select count(*) into p_favorito_existe from Favoritos where ID_Usuario = p_id_usuario and ID_Producto = p_id_producto;
	-- Mensajes de error en caso de que algo no exista
    if p_usuario_existe = 0 then
        select 'Error: El usuario no existe' as mensaje;
    elseif p_producto_existe = 0 then
        select 'Error: El producto no existe' as mensaje;
    elseif p_favorito_existe > 0 then
        select 'Error: El producto ya está en la lista de favoritos' as mensaje;
    else
        -- Inserta en la tabla de favoritos
        insert into Favoritos (ID_Usuario, ID_Producto) values (p_id_usuario, p_id_producto);
        -- Muestra el modelo del producto agregado
        select concat('Producto "', p_modelo_producto, '" agregado a favoritos') as mensaje;
    end if;
end //
delimiter ;
-- Llamada a el procedimiento
call agregarAFavoritos(3, 12);

-- 3. Eliminar favorito
delimiter //
create procedure eliminarDeFavoritos(in p_id_usuario int, in p_id_producto int)
begin
   declare p_usuario_existe int;
   declare p_producto_existe int;
   declare p_favorito_existe int;
   declare p_modelo_producto varchar(60);
   -- Verifica si el usuario existe
   select count(*) into p_usuario_existe from Usuario where ID_Usuario = p_id_usuario;
   -- Verifica si el producto existe
   select count(*) into p_producto_existe from Producto_Neto where ID_Producto = p_id_producto;
   -- Obtiene modelo del producto si existe
   if p_producto_existe > 0 then
       select Modelo into p_modelo_producto from Producto_Neto where ID_Producto = p_id_producto;
   end if;
   -- Verifica si el producto está en favoritos
   select count(*) into p_favorito_existe from Favoritos where ID_Usuario = p_id_usuario and ID_Producto = p_id_producto;
   -- Mensajes de error en caso de que algo no exista o no esté en favoritos
   if p_usuario_existe = 0 then
       select 'Error: El usuario no existe' as mensaje;
   elseif p_producto_existe = 0 then
       select 'Error: El producto no existe' as mensaje;
   elseif p_favorito_existe = 0 then
       select 'Error: El producto no está en la lista de favoritos' as mensaje;
   else
       -- Elimina de la tabla de favoritos
       delete from Favoritos where ID_Usuario = p_id_usuario and ID_Producto = p_id_producto;
       -- Muestra el modelo del producto eliminado
       select concat('Producto "', p_modelo_producto, '" eliminado de favoritos') as mensaje;
   end if;
end //
delimiter ;
-- Llamada a el procedimiento
call eliminarDeFavoritos(3, 12);

-- Triggers
-- 1. Verifica que la talla de un ProductoVenta cuando se inserta esta dentro de rangos normales
delimiter //
create trigger beforeProductoVentasInsert
before insert on Producto_Ventas
for each row
begin
   -- Verifica si la talla está fuera del rango permitido (menor que 25 o mayor que 60)
   if new.Talla < 25 or new.Talla > 60 then
       signal sqlstate '45000'
       set message_text = 'Error: La talla del producto debe estar entre 25 y 60';
   end if;
end //
delimiter ;
-- Insertamos un dato en Producto_Vetnas para activar el trigger
INSERT INTO Producto_Ventas (Precio, Talla, ID_Producto, ID_Compra)
VALUES (100.0, 70, 1, 1);

-- 2. Calcula si el saldo es suficiente para una compra
delimiter //
create trigger beforeCompraInsert
before insert on Compras
for each row
begin
    declare p_saldo_total float;
    -- Obtiene el saldo total del comprador antes de realizar la compra
    select sum(c.Saldo_tarjeta_credito) + sum(c.Saldo_tarjeta_regalo) 
    into p_saldo_total
    from Cartera c
    where c.ID_Cartera = new.ID_Cartera_Comprador;
    -- Verifica si el saldo es suficiente para la compra
    if p_saldo_total is null or p_saldo_total < new.Precio_de_compra then
        signal sqlstate '45000'
        set message_text = 'Error: Saldo insuficiente para realizar la compra';
    end if;
end //
delimiter ;

-- Insertamos un dato para compras para activar el trigger
insert into Compras (Fecha_de_compra, Precio_de_compra, Envio_rapido, ID_Usuario_Vendedor, ID_Cartera_Comprador)
values (CURDATE(), 1500000.00, 1, 1, 1);




