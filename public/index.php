<?php

include __DIR__ . "/../vendor/autoload.php";

use Phalcon\Loader;
use Phalcon\Mvc\View;
use Phalcon\Mvc\Application;
use Phalcon\Di\FactoryDefault;
use Phalcon\Mvc\Url as UrlProvider;
use Phalcon\Db\Adapter\Pdo\Mysql as DbAdapter;
use Phalcon\Mvc\Router;
use App\Controllers\IndexController;

try {
    // Register an autoloader
    $loader = new Loader();
    $loader->registerDirs([
        '../app/controllers/',
        '../app/models/'
    ])->register();

    // Create a DI
    $di = new FactoryDefault();

    // Setup the view component
    $di->set('view', function () {
        $view = new View();
        $view->setViewsDir('../app/views/');
        return $view;
    });

    // Setup a base URI so that all generated URIs include the "tutorial" folder
    $di->set('url', function () {
        $url = new UrlProvider();
        $url->setBaseUri('/tutorial/');
        return $url;
    });

    $di->set(
        'router',
        function () {
            // Create the router
            $router = new Router();

            // Define a route
            $router->add(
                "/",
                [
                    "namespace"  => "App\Controllers",
                    "controller" => "index",
                    "action"     => "index"
                ]
            );

            return $router;
        }
    );

    $application = new Application($di);

    // Handle the request
    $response = $application->handle();

    $response->send();
} catch (\Exception $e) {
    echo "Exception: ", $e->getMessage();
}
