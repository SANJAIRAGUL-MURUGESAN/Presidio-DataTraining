--product table source
CREATE TABLE product_src
(
    product_id INT IDENTITY(1,1) PRIMARY KEY,
    product_name NVARCHAR(100),
    category NVARCHAR(100),
    price DECIMAL(18, 2),
    available_quantity INT
);

--product table target
CREATE TABLE product_tgt
(
    product_id INT PRIMARY KEY,
    product_name NVARCHAR(100),
    category NVARCHAR(100),
    price DECIMAL(18, 2),
    available_quantity INT,
    IsDeleted BIT DEFAULT 0 
);


--table sync  

CREATE OR ALTER PROCEDURE product_sync
(
    @debugFL INT = 0
)
AS
BEGIN
    PRINT 'Product table sync Started';
    IF @debugFL = 1 
    BEGIN
        SELECT * FROM product_src;
        SELECT * FROM product_tgt;
    END

	--INSERT
    INSERT INTO product_tgt (product_id, product_name, category, price, available_quantity)
    SELECT s.product_id, s.product_name, s.category, s.price, s.available_quantity
    FROM product_src s
    LEFT JOIN product_tgt t ON s.product_id = t.product_id
    WHERE t.product_id IS NULL;

	--UPDATE
    UPDATE tgt
    SET 
        tgt.product_name = src.product_name,
        tgt.category = src.category,
        tgt.price = src.price,
        tgt.available_quantity = src.available_quantity
    FROM product_tgt tgt
    INNER JOIN product_src src ON tgt.product_id = src.product_id
    WHERE 
        (tgt.product_name != src.product_name OR
        tgt.category != src.category OR
        tgt.price != src.price OR
        tgt.available_quantity != src.available_quantity);

	-- SOFT DELETE
    UPDATE tgt
    SET tgt.IsDeleted = 1
    FROM product_tgt tgt
    LEFT JOIN product_src s ON tgt.product_id = s.product_id
    WHERE s.product_id IS NULL AND tgt.IsDeleted = 0;

	PRINT 'Product table sync Ended';
END;


EXECUTE product_sync @debugFL = 0
EXECUTE product_sync @debugFL = 1


INSERT INTO product_src (product_name, category, price, available_quantity) 
VALUES 
('Laptop', 'Electronics', 40000, 50),
('Smartphone', 'Electronics', 10000, 75),
('Table', 'Furniture',1500, 30),
('Chair', 'Furniture', 450, 100);


--insert 
INSERT INTO product_src (product_name, category, price, available_quantity) 
VALUES ('Mouse', 'Electronics', 600, 40);
EXECUTE product_sync @debugFL = 1

INSERT INTO product_src (product_name, category, price, available_quantity) 
VALUES ('Keyboard', 'Electronics', 800, 40);
EXECUTE product_sync @debugFL = 1

--update
UPDATE product_src
SET available_quantity = 34
WHERE product_id = 5;

SELECT * FROM product_src
SELECT * FROM product_tgt
EXECUTE product_sync @debugFL = 1

--delete
DELETE FROM product_src
WHERE product_id=6;
SELECT * FROM product_src
SELECT * FROM product_tgt
EXECUTE product_sync @debugFL = 1

--trigger
CREATE or ALTER TRIGGER trg_product_sync
ON product_src
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    EXEC product_sync;
END;


SELECT * FROM product_src
SELECT * FROM product_tgt