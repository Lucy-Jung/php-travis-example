<?php

namespace Test;

use App\Controllers\IndexController;

/**
 * Class UnitTest
 */
class HelloTest extends \UnitTestCase
{
    public function testTestCase()
    {
        $controller = new IndexController();
        $this->assertEquals(
            '<h1>Hello!</h1>',
            $controller->indexAction(),
            'hello! test'
        );
    }
}
