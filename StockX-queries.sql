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

select * from masVentas mv;

-- 2. Vista Beneficios
create view Beneficios as
select Modelo, Precio_retail, avg(pv.Precio), TRUNCATE(AVG(pv.Precio)-Precio_retail,2) as Beneficio
from Producto_Neto pn 
inner join Producto_Ventas pv on pn.ID_Producto = pv.ID_Producto 
group by pn.Modelo, pn.Precio_retail
having Beneficio > 0
order by Beneficio asc;

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
        -- Si el usuario no existe, mostrar un mensaje de error
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

-- 3. Registrar una compra
delimiter //
create procedure registrarCompra(
    in p_id_comprador int, 
    in p_id_vendedor int, 
    in p_id_producto int,
    in p_precio float,
    in p_talla int,
    in p_envio_rapido tinyint
)
begin
    declare p_comprador_existe int;
    declare p_vendedor_existe int;
    declare p_producto_existe int;
    declare p_saldo_total float;
    declare p_id_cartera_comprador int;
    -- Verifica si el comprador existe
    select count(*) into p_comprador_existe from Usuario where ID_Usuario = p_id_comprador;
    -- Verifica si el vendedor existe
    select count(*) into p_vendedor_existe from Usuario where ID_Usuario = p_id_vendedor;
    -- Verifica si el producto existe
    select count(*) into p_producto_existe from Producto_Neto where ID_Producto = p_id_producto;
    -- Obtiene la cartera con mayor saldo del comprador
    select ID_Cartera into p_id_cartera_comprador 
    from Cartera 
    where ID_Usuario = p_id_comprador 
    order by (Saldo_tarjeta_credito + Saldo_tarjeta_regalo) desc 
    limit 1;
    -- Calcula el saldo total disponible del comprador
    select sum(Saldo_tarjeta_credito + Saldo_tarjeta_regalo) into p_saldo_total 
    from Cartera 
    where ID_Usuario = p_id_comprador;
    -- Mensajes de error si algo no existe
    if p_comprador_existe = 0 then
        select 'Error: El comprador no existe' as mensaje;
    elseif p_vendedor_existe = 0 then
        select 'Error: El vendedor no existe' as mensaje;
    elseif p_producto_existe = 0 then
        select 'Error: El producto no existe' as mensaje;
    elseif p_saldo_total < p_precio then
        select 'Error: Saldo insuficiente' as mensaje;
    else
        -- Registra la compra en la tabla Compras
        insert into Compras (Fecha_de_compra, Precio_de_compra, Envio_rapido, ID_Usuario_Vendedor, ID_Cartera_Comprador)
        values (curdate(), p_precio, p_envio_rapido, p_id_vendedor, p_id_cartera_comprador);
        select 'Compra registrada con éxito' as mensaje;
    end if;
end //
delimiter ;
-- Llamada a el procedimiento
CALL registrarCompra(
    2,     -- ID del comprador
    2,     -- ID del vendedor
    101,   -- ID del producto
    250.50,-- Precio del producto
    42,    -- Talla
    1      -- Envio rapido
);

-- IDComprador, IDVendedor, Precio, EnvioRapido, Talla

-- Triggers
-- 1. Inserta una Compra en Producto_Ventas
delimiter //
create trigger afterCompraInsert
after insert on Compras
for each row
begin
    declare p_id_producto int;
    declare p_talla int;
    -- Obtiene el ID del producto desde la tabla Producto_Ventas usando la compra recién insertada
    select ID_Producto, Talla into p_id_producto, p_talla 
    from Producto_Ventas 
    where ID_Compra = new.ID_Compra
    limit 1; -- Suponiendo que solo hay un producto por compra
    -- Verifica si se encontro el producto
    if p_id_producto is not null then
        -- Inserta en Producto_Ventas para asociar el producto a la compra
        insert into Producto_Ventas (Precio, Talla, ID_Producto, ID_Compra)
        values (new.Precio_de_compra, p_talla, p_id_producto, new.ID_Compra);
    end if;
end //
delimiter ;
-- Comprobacion
select * from Compras order by ID_Compra desc limit 5;


-- 2. Calcula si el saldo es suficiente para una compra
-- Este trigger no es necesario si se usa el procedure, ya que viene incluido en el codigo,
-- pero si no se usa, si seria necesario 
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




