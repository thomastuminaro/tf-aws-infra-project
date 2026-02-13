
<?php
/*******************************************************
 * Quick demo page: connect to MySQL (AWS RDS) and list users
 * Requirements: PHP with PDO + pdo_mysql extension
 *******************************************************/

$host = 'terraform-20260213113342838700000004.cqedc7azcz8o.eu-west-3.rds.amazonaws.com';
$db   = 'dbweb';
$user = 'admin';
$pass = 'adminadmin';
$port = 3306;

$dsn = "mysql:host=$host;port=$port;dbname=$db;charset=utf8mb4";

try {
    // Use PDO for robust error handling
    $pdo = new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);
} catch (PDOException $e) {
    http_response_code(500);
    echo "<h1>Database connection failed</h1>";
    echo "<pre>" . htmlspecialchars($e->getMessage(), ENT_QUOTES, 'UTF-8') . "</pre>";
    exit;
}

// Query all users (assumes a table named `users`)
try {
    $stmt = $pdo->query("SELECT * FROM users");
    $rows = $stmt->fetchAll();
} catch (PDOException $e) {
    http_response_code(500);
    echo "<h1>Query failed</h1>";
    echo "<pre>" . htmlspecialchars($e->getMessage(), ENT_QUOTES, 'UTF-8') . "</pre>";
    exit;
}
?>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>My Site</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: system-ui, Arial, sans-serif; margin: 2rem; }
    h1 { margin-bottom: 1rem; }
    table { border-collapse: collapse; width: 100%; max-width: 960px; }
    th, td { border: 1px solid #ccc; padding: .5rem .75rem; text-align: left; }
    th { background: #f6f6f6; }
    caption { text-align: left; margin: .5rem 0; font-weight: 600; }
    .muted { color: #666; }
  </style>
</head>
<body>
  <h1>welcome to my site</h1>

  <?php if (empty($rows)): ?>
    <p class="muted">No users found in the <code>users</code> table.</p>
  <?php else: ?>
    <table>
      <caption>Users</caption>
      <thead>
        <tr>
          <?php foreach (array_keys($rows[0]) as $col): ?>
            <th><?= htmlspecialchars($col, ENT_QUOTES, 'UTF-8') ?></th>
          <?php endforeach; ?>
        </tr>
      </thead>
      <tbody>
        <?php foreach ($rows as $r): ?>
          <tr>
            <?php foreach ($r as $val): ?>
              <td><?= htmlspecialchars((string)$val, ENT_QUOTES, 'UTF-8') ?></td>
            <?php endforeach; ?>
          </tr>
        <?php endforeach; ?>
      </tbody>
    </table>
  <?php endif; ?>
</body>
</html>